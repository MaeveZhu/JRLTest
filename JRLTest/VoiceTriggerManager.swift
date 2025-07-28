import Foundation
import Speech
import AVFoundation

class VoiceTriggerManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var triggerDetected = false
    
    var onTrigger: (() -> Void)?
    
    override init() {
        super.init()
        recognizer?.delegate = self
        // 延迟设置音频会话，避免启动时崩溃
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupAudioSession()
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    func startListening() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw VoiceTriggerError.recognizerNotAvailable
        }
        
        // 确保音频会话已设置
        setupAudioSession()
        
        // 重置状态
        triggerDetected = false
        recognizedText = ""
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("语音识别错误: \(error)")
                return
            }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                    
                    // 检测关键词
                    if text.contains("开始记录") || text.contains("开始录音") || text.contains("开始录制") {
                        if !self.triggerDetected {
                            self.triggerDetected = true
                            self.onTrigger?()
                        }
                    }
                }
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        request.endAudio()
        isListening = false
    }
    
    func resetTrigger() {
        triggerDetected = false
    }
}

enum VoiceTriggerError: Error {
    case recognizerNotAvailable
    case audioEngineError
} 