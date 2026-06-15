import AVFoundation
import UIKit

protocol ExamSafeModePhotoCapturing: AnyObject {
    func start() async throws
    func captureLowQualityJPEG() async throws -> Data
    func stop()
}

final class ExamSafeModePhotoCapturer: NSObject, ExamSafeModePhotoCapturing {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var captureDelegate: PhotoCaptureDelegate?

    func start() async throws {
        #if targetEnvironment(simulator)
        return
        #else
        guard !session.isRunning else { return }
        try configureIfNeeded()
        session.startRunning()
        #endif
    }

    func captureLowQualityJPEG() async throws -> Data {
        #if targetEnvironment(simulator)
        return try await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first else {
                throw ExamSafeModeCameraError.photoDataUnavailable
            }

            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let image = renderer.image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            guard let resized = image.examSafeModeResized(maxDimension: 480),
                  let jpeg = resized.jpegData(compressionQuality: 0.22) else {
                throw ExamSafeModeCameraError.photoDataUnavailable
            }
            return jpeg
        }
        #else
        guard session.isRunning else {
            try await start()
            return try await captureLowQualityJPEG()
        }

        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            settings.photoQualityPrioritization = .speed

            let delegate = PhotoCaptureDelegate { [weak self] result in
                self?.captureDelegate = nil
                continuation.resume(with: result)
            }
            captureDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
        #endif
    }

    func stop() {
        #if !targetEnvironment(simulator)
        if session.isRunning {
            session.stopRunning()
        }
        #endif
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .low
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            throw ExamSafeModeCameraError.cameraUnavailable
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            throw ExamSafeModeCameraError.configurationFailed
        }

        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .speed
        isConfigured = true
    }
}

enum ExamSafeModeCameraError: LocalizedError {
    case cameraUnavailable
    case configurationFailed
    case photoDataUnavailable

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is unavailable."
        case .configurationFailed:
            return "Camera configuration failed."
        case .photoDataUnavailable:
            return "Photo data is unavailable."
        }
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Data, Error>) -> Void

    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data),
              let resized = image.examSafeModeResized(maxDimension: 480),
              let jpeg = resized.jpegData(compressionQuality: 0.22) else {
            completion(.failure(ExamSafeModeCameraError.photoDataUnavailable))
            return
        }

        completion(.success(jpeg))
    }
}

private extension UIImage {
    func examSafeModeResized(maxDimension: CGFloat) -> UIImage? {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
