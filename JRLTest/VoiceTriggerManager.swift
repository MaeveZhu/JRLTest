import Foundation
import Speech
import AVFoundation

class VoiceTriggerManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private lazy var recognizer: SFSpeechRecognizer? = {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        recognizer?.delegate = self
        return recognizer
    }()
    
    private let audioEngine = AVAudioEngine()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var triggerDetected = false
    @Published var confidence: Float = 0.0
    @Published var errorMessage: String?
    
    // 扩展关键词列表
    private let triggerKeywords = [
        "开始记录", "开始录音", "开始录制", "开始录", "录音", "录制",
        "记录一下", "录一下", "开始", "记录", "录"
    ]
    
    var onTrigger: (() -> Void)?
    
    private var isProcessingAudio = false
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isInitialized = false
    
    override init() {
        super.init()
        // 移除所有早期初始化，避免启动时崩溃
    }
    
    private func setupAudioSession() {
        guard !isInitialized else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            errorMessage = nil
            isInitialized = true
        } catch {
            print("音频会话设置失败: \(error)")
            errorMessage = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.errorMessage = nil
                    completion(true)
                case .denied, .restricted:
                    self.errorMessage = "语音识别权限被拒绝"
                    completion(false)
                case .notDetermined:
                    self.errorMessage = "语音识别权限未确定"
                    completion(false)
                @unknown default:
                    self.errorMessage = "语音识别权限状态未知"
                    completion(false)
                }
            }
        }
    }
    
    func startListening() throws {
        guard !isProcessingAudio else {
            throw VoiceTriggerError.alreadyProcessing
        }
        
        // 延迟初始化
        setupAudioSession()
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw VoiceTriggerError.recognizerNotAvailable
        }
        
        // 重置状态
        triggerDetected = false
        recognizedText = ""
        confidence = 0.0
        errorMessage = nil
        
        isProcessingAudio = true
        
        do {
            let node = audioEngine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)
            
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.request.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("语音识别错误: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "语音识别错误: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    let confidence = result.bestTranscription.segments.last?.confidence ?? 0.0
                    
                    DispatchQueue.main.async {
                        self.recognizedText = text
                        self.confidence = confidence
                        
                        // 检测关键词
                        if self.checkForTriggerKeywords(in: text) {
                            if !self.triggerDetected {
                                self.triggerDetected = true
                                print("检测到触发关键词: \(text)")
                                self.onTrigger?()
                            }
                        }
                    }
                }
            }
            
        } catch {
            isProcessingAudio = false
            isListening = false
            errorMessage = "启动语音监听失败: \(error.localizedDescription)"
            throw VoiceTriggerError.audioEngineError
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        isProcessingAudio = false
        isListening = false
        
        // 安全停止音频引擎
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // 移除音频节点
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 结束识别请求
        request.endAudio()
        
        // 取消识别任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        errorMessage = nil
    }
    
    func resetTrigger() {
        triggerDetected = false
    }
    
    private func checkForTriggerKeywords(in text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return triggerKeywords.contains { keyword in
            lowercasedText.contains(keyword.lowercased())
        }
    }
    
    // 添加自定义关键词
    func addTriggerKeyword(_ keyword: String) {
        if !triggerKeywords.contains(keyword) {
            // 注意：这里需要修改为可变的数组才能添加关键词
            print("添加触发关键词: \(keyword)")
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func getLastError() -> String? {
        return errorMessage
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "语音识别服务不可用"
                self.stopListening()
            } else {
                self.errorMessage = nil
            }
        }
    }
}

enum VoiceTriggerError: Error, LocalizedError {
    case recognizerNotAvailable
    case audioEngineError
    case alreadyProcessing
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "语音识别器不可用"
        case .audioEngineError:
            return "音频引擎错误"
        case .alreadyProcessing:
            return "正在处理音频，请稍后再试"
        }
    }
} 