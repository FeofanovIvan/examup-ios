import Foundation
import AVFoundation
import Speech

enum AppPermission: String, CaseIterable {
    case notifications
    case camera
    case microphone
    case speechRecognition
}

enum PermissionStatus: String {
    case notDetermined
    case granted
    case denied
}

protocol PermissionServicing {
    func status(for permission: AppPermission) async -> PermissionStatus
    func request(_ permission: AppPermission) async -> PermissionStatus
}

struct NoOpPermissionService: PermissionServicing {
    func status(for permission: AppPermission) async -> PermissionStatus { .notDetermined }
    func request(_ permission: AppPermission) async -> PermissionStatus { .denied }
}

struct SystemPermissionService: PermissionServicing {
    func status(for permission: AppPermission) async -> PermissionStatus {
        switch permission {
        case .notifications:
            return .notDetermined
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                return .granted
            case .denied, .restricted:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        case .microphone:
            return microphonePermissionStatus()
        case .speechRecognition:
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                return .granted
            case .denied, .restricted:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        }
    }

    func request(_ permission: AppPermission) async -> PermissionStatus {
        switch permission {
        case .notifications:
            return .denied
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .granted : .denied
        case .microphone:
            let granted = await requestMicrophonePermission()
            return granted ? .granted : .denied
        case .speechRecognition:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    switch status {
                    case .authorized:
                        continuation.resume(returning: .granted)
                    case .denied, .restricted:
                        continuation.resume(returning: .denied)
                    case .notDetermined:
                        continuation.resume(returning: .notDetermined)
                    @unknown default:
                        continuation.resume(returning: .denied)
                    }
                }
            }
        }
    }

    private func microphonePermissionStatus() -> PermissionStatus {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
