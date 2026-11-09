import AVFoundation
import Foundation
import Speech

/// 실제 기기의 마이크·음성 인식 권한입니다.
@MainActor
final class SystemRecordingPermissions: RecordingPermissionProviding {
    nonisolated init() {}

    var status: RecordingPermissionStatus {
        Self.combine(speech: SFSpeechRecognizer.authorizationStatus(), microphone: AVAudioApplication.shared.recordPermission)
    }

    func requestAuthorization() async -> RecordingPermissionStatus {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        return Self.combine(speech: speech, microphone: microphone ? .granted : .denied)
    }

    private static func combine(
        speech: SFSpeechRecognizerAuthorizationStatus,
        microphone: AVAudioApplication.recordPermission
    ) -> RecordingPermissionStatus {
        if speech == .authorized && microphone == .granted { return .authorized }
        if speech == .notDetermined || microphone == .undetermined { return .notDetermined }
        return .denied
    }
}

/// AVAudioEngine과 SFSpeechRecognizer를 사용하는 실제 녹음 장치입니다.
@MainActor
final class SpeechRecordingCapture: RecordingCapturing {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var isSessionActive = false
    private var isTapInstalled = false
    /// 새 `begin`/`release`마다 증가하여 이전 인식의 늦은 콜백을 버립니다.
    private var generation = 0

    nonisolated init() {}

    func begin(onEvent: @escaping @MainActor (RecordingCaptureEvent) -> Void) throws {
        release()
        generation += 1
        let generation = generation

        guard let recognizer, recognizer.isAvailable else { throw RecordingCaptureError() }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            isSessionActive = true
        } catch {
            AppLog.audio.error("녹음 오디오 세션 설정 실패")
            release()
            throw RecordingCaptureError()
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isEnded = error != nil || (result?.isFinal ?? false)
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                if isEnded {
                    onEvent(.ended(text))
                } else if let text {
                    onEvent(.partial(text))
                }
            }
        }

        let inputNode = audioEngine.inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        isTapInstalled = true
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            AppLog.audio.error("녹음 오디오 엔진 시작 실패")
            release()
            throw RecordingCaptureError()
        }
    }

    func endAudio() {
        stopEngine()
        request?.endAudio()
    }

    func release() {
        generation += 1
        stopEngine()
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        if isSessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        }
    }

    private func stopEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // 시작에 실패한 경우에도 tap이 남지 않도록 설치된 tap은 항상 제거합니다.
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
    }
}
