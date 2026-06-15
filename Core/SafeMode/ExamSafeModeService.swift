import Foundation
import Vision

protocol ExamSafeModeServicing {
    func start(configuration: ExamSafeModeConfiguration) async -> Bool
    func stop() async
    /// Stops the session, runs Vision + keyword analysis, saves report + PDF,
    /// enqueues to Firestore outbox, and returns the finished report.
    func stopAndReport() async -> ExamSafeModeReport?
}

actor ExamSafeModeService: ExamSafeModeServicing {
    private let permissionService: PermissionServicing
    private let archiveStore: ExamSafeModeArchiveStoring
    private let photoCapturer: ExamSafeModePhotoCapturing
    private let audioTranscriber: ExamSafeModeAudioTranscribing
    private let localDatabase: LocalDatabase
    private let syncService: SyncServicing
    private var captureTask: Task<Void, Never>?
    private var activeArchive: ExamSafeModeArchive?
    private var lastTranscriptText = ""

    init(
        permissionService: PermissionServicing,
        localDatabase: LocalDatabase,
        syncService: SyncServicing,
        archiveStore: ExamSafeModeArchiveStoring = FileExamSafeModeArchiveStore(),
        photoCapturer: ExamSafeModePhotoCapturing = ExamSafeModePhotoCapturer(),
        audioTranscriber: ExamSafeModeAudioTranscribing = SpeechExamSafeModeAudioTranscriber()
    ) {
        self.permissionService = permissionService
        self.localDatabase = localDatabase
        self.syncService = syncService
        self.archiveStore = archiveStore
        self.photoCapturer = photoCapturer
        self.audioTranscriber = audioTranscriber
    }

    func start(configuration: ExamSafeModeConfiguration) async -> Bool {
        await stop()

        do {
            let archive = try await archiveStore.createArchive(sessionID: configuration.sessionID)
            activeArchive = archive
            lastTranscriptText = ""
            var allRequestedSensorsStarted = true

            if configuration.recordsCamera {
                let cameraStarted = await startCamera(configuration: configuration, archive: archive)
                allRequestedSensorsStarted = allRequestedSensorsStarted && cameraStarted
            }

            if configuration.recordsMicrophone {
                let microphoneStarted = await startMicrophone(configuration: configuration)
                allRequestedSensorsStarted = allRequestedSensorsStarted && microphoneStarted
            }
            return allRequestedSensorsStarted
        } catch {
            #if DEBUG
            print("[SafeMode] failed to start session=\(configuration.sessionID): \(error.localizedDescription)")
            #endif
            return false
        }
    }

    func stop() async {
        captureTask?.cancel()
        captureTask = nil
        photoCapturer.stop()
        audioTranscriber.stop()

        if let archive = activeArchive {
            do {
                let finishedArchive = try await archiveStore.finishArchive(archive)
                #if DEBUG
                print("[SafeMode] stopped session=\(finishedArchive.sessionID) captures=\(finishedArchive.captures.count) transcriptSegments=\(finishedArchive.transcriptSegments.count)")
                #endif
            } catch {
                #if DEBUG
                print("[SafeMode] failed to finish archive: \(error.localizedDescription)")
                #endif
            }
        }
        activeArchive = nil
    }

    func stopAndReport() async -> ExamSafeModeReport? {
        captureTask?.cancel()
        captureTask = nil
        photoCapturer.stop()
        audioTranscriber.stop()

        guard var archive = activeArchive else {
            activeArchive = nil
            return nil
        }

        do {
            archive = try await archiveStore.finishArchive(archive)
        } catch {
            #if DEBUG
            print("[SafeMode] failed to finish archive: \(error.localizedDescription)")
            #endif
        }

        // Build report (scoring + summary)
        let report = ExamSafeModeAnalyzer.buildReport(from: archive)

        // Generate PDF
        let pdfData = ExamSafeModePDFExporter.export(report: report, archive: archive)

        // Persist report JSON + PDF into archive folder
        do {
            archive = try await archiveStore.saveReport(report, pdfData: pdfData, archive: archive)
        } catch {
            #if DEBUG
            print("[SafeMode] failed to save report: \(error.localizedDescription)")
            #endif
        }

        // Enqueue to Firestore via outbox
        await enqueueReportToFirestore(report)

        activeArchive = nil
        #if DEBUG
        print("[SafeMode] report generated session=\(report.sessionID) score=\(report.score) verdict=\(report.verdict.rawValue)")
        #endif
        return report
    }

    // MARK: - Camera

    private func startCamera(configuration: ExamSafeModeConfiguration, archive: ExamSafeModeArchive) async -> Bool {
        #if targetEnvironment(simulator)
        let permission: PermissionStatus = .granted
        #else
        let permission = await resolvePermission(.camera)
        #endif
        guard permission == .granted else {
            #if DEBUG
            print("[SafeMode][Camera] permission denied session=\(configuration.sessionID)")
            #endif
            return false
        }

        do {
            try await photoCapturer.start()
            let offsets = ExamSafeModeCaptureSchedule.offsets(
                durationSeconds: configuration.durationSeconds,
                maxCaptures: configuration.maxCaptures
            )

            #if DEBUG
            print("[SafeMode][Camera] started session=\(configuration.sessionID) captures=\(offsets.count) folder=\(archive.folderURL.path)")
            #endif

            captureTask = Task { [weak self] in
                let startDate = Date()
                for (index, offset) in offsets.enumerated() {
                    guard !Task.isCancelled else { return }
                    let targetDate = startDate.addingTimeInterval(TimeInterval(offset))
                    let delay = max(0, targetDate.timeIntervalSinceNow)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    await self?.capture(index: index + 1, scheduledOffset: offset)
                }
            }
            return true
        } catch {
            #if DEBUG
            print("[SafeMode][Camera] failed to start session=\(configuration.sessionID): \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Microphone

    private func startMicrophone(configuration: ExamSafeModeConfiguration) async -> Bool {
        let microphonePermission = await resolvePermission(.microphone)
        let speechPermission = await resolvePermission(.speechRecognition)
        guard microphonePermission == .granted, speechPermission == .granted else {
            #if DEBUG
            print("[SafeMode][Audio] permission denied session=\(configuration.sessionID)")
            #endif
            return false
        }

        do {
            try await audioTranscriber.start(localeIdentifier: "ru_RU") { [weak self] update in
                Task {
                    await self?.saveTranscript(update)
                }
            }
            #if DEBUG
            print("[SafeMode][Audio] started session=\(configuration.sessionID)")
            #endif
            return true
        } catch {
            #if DEBUG
            print("[SafeMode][Audio] failed to start session=\(configuration.sessionID): \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Helpers

    private func resolvePermission(_ permission: AppPermission) async -> PermissionStatus {
        let status = await permissionService.status(for: permission)
        if status == .notDetermined {
            return await permissionService.request(permission)
        }
        return status
    }

    private func capture(index: Int, scheduledOffset: Int) async {
        guard let archive = activeArchive else { return }

        do {
            let jpegData = try await photoCapturer.captureLowQualityJPEG()

            // Run Vision face detection off the main thread
            let faceResult = await Task.detached(priority: .userInitiated) {
                ExamSafeModeAnalyzer.analyzeFaces(in: jpegData)
            }.value

            let capture = ExamSafeModeCapture(
                id: UUID().uuidString,
                index: index,
                filename: String(format: "capture_%02d.jpg", index),
                capturedAt: Date(),
                scheduledOffsetSeconds: scheduledOffset,
                quality: "low",
                faceCount: faceResult.faceCount,
                userPresence: faceResult.userPresence,
                gazeStatus: faceResult.gazeStatus
            )

            let updatedArchive = try await archiveStore.saveCapture(jpegData, capture: capture, archive: archive)
            activeArchive = updatedArchive

            #if DEBUG
            print("[SafeMode][Camera] captured session=\(archive.sessionID) index=\(index) faces=\(faceResult.faceCount) presence=\(faceResult.userPresence.rawValue) gaze=\(faceResult.gazeStatus.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("[SafeMode][Camera] capture failed session=\(archive.sessionID) index=\(index): \(error.localizedDescription)")
            #endif
        }
    }

    private func saveTranscript(_ update: ExamSafeModeTranscriptUpdate) async {
        guard let archive = activeArchive else { return }
        let normalizedText = update.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty, normalizedText != lastTranscriptText else { return }
        lastTranscriptText = normalizedText

        let segment = ExamSafeModeTranscriptSegment(
            id: UUID().uuidString,
            text: normalizedText,
            capturedAt: Date(),
            localeIdentifier: update.localeIdentifier,
            isFinal: update.isFinal
        )

        do {
            let updatedArchive = try await archiveStore.saveTranscriptSegment(segment, archive: archive)
            activeArchive = updatedArchive
        } catch {
            #if DEBUG
            print("[SafeMode][Audio] transcript save failed session=\(archive.sessionID): \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Firestore outbox

    private func enqueueReportToFirestore(_ report: ExamSafeModeReport) async {
        let document = SyncDocument(fields: [
            "sessionID":               .string(report.sessionID),
            "score":                   .int(report.score),
            "verdict":                 .string(report.verdict.rawValue),
            "summary":                 .string(report.summary),
            "flags":                   .strings(report.flags.map(\.rawValue)),
            "totalCaptureCount":       .int(report.totalCaptureCount ?? 0),
            "captureFindingsCount":    .int(report.captureFindingsCount),
            "transcriptFindingsCount": .int(report.transcriptFindingsCount),
            "generatedAt":             .serverTimestamp,
            "createdAt":               .serverTimestamp
        ])
        do {
            let payload = try document.encoded()
            let mutation = SyncMutation(
                collection: "safemode_reports",
                documentID: report.sessionID,
                operation: .set,
                payload: payload
            )
            try await localDatabase.enqueue(mutation)
            await syncService.scheduleSync(for: .exams)
        } catch {
            #if DEBUG
            print("[SafeMode] failed to enqueue report to Firestore: \(error.localizedDescription)")
            #endif
        }
    }
}
