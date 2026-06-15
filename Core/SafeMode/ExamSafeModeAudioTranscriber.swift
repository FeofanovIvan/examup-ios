import AVFoundation
import Speech

struct ExamSafeModeTranscriptUpdate: Equatable {
    let text: String
    let localeIdentifier: String
    let isFinal: Bool
}

protocol ExamSafeModeAudioTranscribing: AnyObject {
    func start(localeIdentifier: String, onTranscript: @escaping (ExamSafeModeTranscriptUpdate) -> Void) async throws
    func stop()
}

final class SpeechExamSafeModeAudioTranscriber: ExamSafeModeAudioTranscribing {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    func start(localeIdentifier: String = "ru_RU", onTranscript: @escaping (ExamSafeModeTranscriptUpdate) -> Void) async throws {
        stop()

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
              recognizer.isAvailable else {
            throw ExamSafeModeAudioError.speechRecognizerUnavailable
        }

        speechRecognizer = recognizer
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                onTranscript(
                    ExamSafeModeTranscriptUpdate(
                        text: text,
                        localeIdentifier: localeIdentifier,
                        isFinal: result.isFinal
                    )
                )
            }

            if error != nil {
                request.endAudio()
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

enum ExamSafeModeAudioError: LocalizedError {
    case speechRecognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "Speech recognizer is unavailable."
        }
    }
}
