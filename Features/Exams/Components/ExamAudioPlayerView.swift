import AVFoundation
import SwiftUI

struct ExamAudioPlayerView: View {
    let source: String

    @State private var player: AVPlayer?
    @State private var loadedSource: String?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var isUnavailable = false

    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(playerTint.opacity(isUnavailable ? 0.42 : 1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isUnavailable)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Аудио к заданию")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))

                    Text(isUnavailable ? "Файл не найден в сборке" : "Прослушайте запись перед ответом")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "70788A"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Text(formatTime(currentTime))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "70788A"))
                    .frame(width: 38, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { currentTime },
                        set: { seek(to: $0) }
                    ),
                    in: 0...max(duration, 1)
                )
                .tint(playerTint)
                .disabled(isUnavailable)

                Text(formatTime(duration))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "70788A"))
                    .frame(width: 38, alignment: .trailing)
            }
        }
        .padding(14)
        .background(Color(hex: "F7F4FF"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "E3DBFF"), lineWidth: 1)
        }
        .onAppear(perform: configurePlayerIfNeeded)
        .onChange(of: source) {
            resetPlayer()
            configurePlayerIfNeeded()
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
        .onReceive(timer) { _ in
            syncPlaybackState()
        }
    }

    private var playerTint: Color {
        Color(hex: "7257F4")
    }

    private func configurePlayerIfNeeded() {
        guard loadedSource != source else { return }
        loadedSource = source

        guard let url = ExamAudioResourceResolver.url(for: source) else {
            isUnavailable = true
            return
        }

        isUnavailable = false
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        syncPlaybackState()
    }

    private func togglePlayback() {
        configurePlayerIfNeeded()
        guard let player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func seek(to seconds: Double) {
        currentTime = seconds
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    private func resetPlayer() {
        player?.pause()
        player = nil
        loadedSource = nil
        isPlaying = false
        currentTime = 0
        duration = 1
        isUnavailable = false
    }

    private func syncPlaybackState() {
        guard let player else { return }
        currentTime = max(0, player.currentTime().seconds)

        if let itemDuration = player.currentItem?.duration.seconds,
           itemDuration.isFinite,
           itemDuration > 0 {
            duration = itemDuration
        }

        if currentTime >= duration, duration > 1 {
            isPlaying = false
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let safeSeconds = max(Int(seconds.rounded(.down)), 0)
        return "\(safeSeconds / 60):\(String(format: "%02d", safeSeconds % 60))"
    }
}

enum ExamAudioResourceResolver {
    static func url(for source: String) -> URL? {
        let decoded = source.removingPercentEncoding ?? source
        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)

        // examup-media://media_id — resolve by searching known media folders in the bundle
        if let parsed = URL(string: trimmed), parsed.scheme == "examup-media" {
            return ExamBundleMediaResolver.fileURL(forMediaID: parsed.host ?? parsed.path)
        }

        if let remoteURL = URL(string: trimmed),
           remoteURL.scheme == "http" || remoteURL.scheme == "https" || remoteURL.scheme == "file" {
            if remoteURL.isFileURL {
                return FileManager.default.fileExists(atPath: remoteURL.path) ? remoteURL : nil
            }
            return remoteURL
        }

        let relativePath = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fileName = URL(fileURLWithPath: relativePath).lastPathComponent
        let fileStem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let fileExtension = URL(fileURLWithPath: fileName).pathExtension

        var candidates = [
            Bundle.main.resourceURL.map { $0.appendingPathComponent(relativePath) },
            Bundle.main.resourceURL.map { $0.appendingPathComponent("SeedData").appendingPathComponent(relativePath) },
            Bundle.main.url(forResource: fileStem, withExtension: fileExtension)
        ].compactMap { $0 }
        candidates.append(contentsOf: ExamBundleMediaResolver.downloadedCandidates(for: relativePath))

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
}

/// Resolves examup-media:// IDs to bundled file URLs across all known media folders.
enum ExamBundleMediaResolver {
    private static let mediaFolders = [
        "russian_resources_free",
        "english_media",
    ]
    private static let knownExtensions = ["m4a", "mp3", "wav", "webp", "png", "jpg", "jpeg", "svg"]

    static func fileURL(forMediaID mediaID: String) -> URL? {
        guard !mediaID.isEmpty else { return nil }
        for candidate in downloadedCandidates(for: mediaID) where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        for folder in mediaFolders {
            for ext in knownExtensions {
                let candidate = resourceURL
                    .appendingPathComponent(folder)
                    .appendingPathComponent("\(mediaID).\(ext)")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }
        return nil
    }

    static func downloadedCandidates(for pathOrMediaID: String) -> [URL] {
        let fileManager = FileManager.default
        guard let root = try? SubjectLibraryCatalog.librariesRootURL(fileManager: fileManager),
              let subjectFolders = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let relativePath = pathOrMediaID.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suppliedExtension = URL(fileURLWithPath: relativePath).pathExtension
        return subjectFolders.flatMap { subjectFolder in
            let resources = subjectFolder.appendingPathComponent("resources", isDirectory: true)
            if !suppliedExtension.isEmpty {
                var candidates = [
                    subjectFolder.appendingPathComponent(relativePath),
                    resources.appendingPathComponent(relativePath)
                ]
                if relativePath.hasPrefix("resources/") {
                    candidates.append(
                        resources.appendingPathComponent(String(relativePath.dropFirst("resources/".count)))
                    )
                }
                return candidates
            }
            return knownExtensions.map { resources.appendingPathComponent("\(relativePath).\($0)") }
        }
    }
}
