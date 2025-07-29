import Foundation
import Speech
import AVFoundation
import Intents
import CoreLocation

class VoiceRecordingManager: NSObject, ObservableObject {
    static let shared = VoiceRecordingManager()
    
    @Published var isListening = false
    @Published var isRecording = false
    @Published var currentTestSession: TestSession?
    @Published var recordingSegments: [RecordingSegment] = []
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private var audioRecorder: AVAudioRecorder?
    private var silenceTimer: Timer?
    private var recordingStartTime: Date?
    private var currentSegmentNumber = 1
    
    // 添加状态管理
    private var isEngineRunning = false
    private var hasTapInstalled = false
    
    // 触发关键词
    private let triggerKeywords = ["开始记录", "开始录音", "记录开始", "start recording", "hey siri", "嘿siri"]
    
    override init() {
        super.init()
        setupSpeechRecognizer()
        requestPermissions()
    }
    
    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        speechRecognizer?.delegate = self
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("❌ Speech recognition not authorized")
                @unknown default:
                    print("❌ Unknown speech recognition status")
                }
            }
        }
    }
    
    // MARK: - Test Session Management
    func startTestSession(vin: String, testExecutionId: String, tag: String, startCoordinate: CLLocationCoordinate2D?) {
        currentTestSession = TestSession(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: tag,
            startCoordinate: startCoordinate,
            startTime: Date()
        )
        recordingSegments = []
        currentSegmentNumber = 1
        
        // 延迟启动避免UI冲突
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startListening()
        }
        
        print("✅ Test session started for VIN: \(vin)")
    }
    
    func endTestSession(endCoordinate: CLLocationCoordinate2D?) -> TestSession? {
        guard var session = currentTestSession else { return nil }
        
        // 完全停止所有音频操作
        completelyStopAudio()
        
        session.endCoordinate = endCoordinate
        session.endTime = Date()
        session.recordingSegments = recordingSegments
        
        saveTestSession(session)
        
        // 重置状态
        currentTestSession = nil
        recordingSegments = []
        currentSegmentNumber = 1
        
        print("✅ Test session ended for VIN: \(session.vin)")
        return session
    }
    
    // MARK: - Audio Management
    private func completelyStopAudio() {
        print("🛑 Completely stopping all audio operations")
        
        // 停止录音
        if isRecording {
            audioRecorder?.stop()
            audioRecorder = nil
            isRecording = false
        }
        
        // 停止语音识别
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        // 停止音频引擎
        if isEngineRunning {
            audioEngine.stop()
            isEngineRunning = false
        }
        
        // 移除tap
        if hasTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTapInstalled = false
        }
        
        // 停止计时器
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        isListening = false
        
        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Error deactivating audio session: \(error)")
        }
        
        print("✅ All audio operations stopped")
    }
    
    // MARK: - Voice Recognition
    func startListening() {
        guard !isListening, currentTestSession != nil else { 
            print("❌ Cannot start listening: already listening or no session")
            return 
        }
        
        print("🎤 Starting voice listening...")
        
        // 确保完全清理之前的状态
        completelyStopAudio()
        
        // 等待一下再启动，确保清理完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.actuallyStartListening()
        }
    }
    
    private func actuallyStartListening() {
        do {
            // 1. 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true)
            
            // 2. 创建新的识别请求
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                print("❌ Cannot create recognition request")
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            
            // 3. 重新创建音频引擎（确保干净状态）
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // 4. 安装tap
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            hasTapInstalled = true
            
            // 5. 启动音频引擎
            audioEngine.prepare()
            try audioEngine.start()
            isEngineRunning = true
            
            // 6. 开始识别任务
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        let spokenText = result.bestTranscription.formattedString
                        self?.processSpokenText(spokenText)
                    }
                    
                    if let error = error {
                        print("❌ Recognition error: \(error)")
                        // 重试机制
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self?.currentTestSession != nil && self?.isListening == true {
                                self?.startListening()
                            }
                        }
                    }
                }
            }
            
            isListening = true
            print("✅ Voice listening started successfully")
            
        } catch {
            print("❌ Failed to start listening: \(error)")
            completelyStopAudio()
            
            // 重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.currentTestSession != nil {
                    self.startListening()
                }
            }
        }
    }
    
    func stopListening() {
        print("🛑 Stopping voice listening...")
        completelyStopAudio()
    }
    
    private func processSpokenText(_ text: String) {
        print("🎤 Heard: \(text)")
        
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查触发词
        for keyword in triggerKeywords {
            if normalizedText.contains(keyword.lowercased()) {
                print("✅ Trigger word detected: \(keyword)")
                startVoiceTriggeredRecording()
                return
            }
        }
    }
    
    // MARK: - Recording Management
    private func startVoiceTriggeredRecording() {
        guard !isRecording, let session = currentTestSession else {
            print("❌ Cannot start recording: already recording or no session")
            return
        }
        
        print("🎙️ Starting voice-triggered recording...")
        
        // 完全停止语音监听
        completelyStopAudio()
        
        // 等待一下再开始录音
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.actuallyStartRecording()
        }
    }
    
    private func actuallyStartRecording() {
        guard let session = currentTestSession else { return }
        
        do {
            // 1. 配置音频会话为录音
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            // 2. 创建录音文件
            let fileName = "segment_\(currentSegmentNumber)_\(Date().timeIntervalSince1970).m4a"
            let recordingsURL = try createRecordingsDirectory()
            let fileURL = recordingsURL.appendingPathComponent(fileName)
            
            // 3. 录音设置
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // 4. 创建录音器
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            recordingStartTime = Date()
            isRecording = true
            
            // 5. 开始静音检测
            startSilenceDetection()
            
            print("✅ Recording started: \(fileName)")
            
        } catch {
            print("❌ Recording failed: \(error)")
            
            // 录音失败，重新开始监听
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.currentTestSession != nil {
                    self.startListening()
                }
            }
        }
    }
    
    private func stopCurrentRecording() {
        guard isRecording, let recorder = audioRecorder else { return }
        
        print("🛑 Stopping current recording...")
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        recorder.stop()
        
        // 创建录音片段
        if let startTime = recordingStartTime,
           let session = currentTestSession {
            let segment = RecordingSegment(
                id: UUID(),
                segmentNumber: currentSegmentNumber,
                fileName: recorder.url.lastPathComponent,
                fileURL: recorder.url,
                startTime: startTime,
                endTime: Date(),
                vin: session.vin,
                testExecutionId: session.testExecutionId,
                tag: session.tag
            )
            
            recordingSegments.append(segment)
            currentSegmentNumber += 1
            
            print("✅ Recording segment \(segment.segmentNumber) saved")
        }
        
        audioRecorder = nil
        recordingStartTime = nil
        isRecording = false
        
        // 录音结束后，重新开始监听
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.currentTestSession != nil {
                self.startListening()
            }
        }
    }
    
    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            print("🔇 3-second silence detected")
            DispatchQueue.main.async {
                self?.stopCurrentRecording()
            }
        }
    }
    
    // MARK: - File Management
    private func createRecordingsDirectory() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsURL = documentsPath.appendingPathComponent("VoiceRecordings")
        
        if !FileManager.default.fileExists(atPath: recordingsURL.path) {
            try FileManager.default.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
        }
        
        return recordingsURL
    }
    
    // MARK: - Data Persistence
    private func saveTestSession(_ session: TestSession) {
        var sessions = getTestSessions()
        sessions.append(session)
        
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "TestSessions")
        }
    }
    
    func getTestSessions() -> [TestSession] {
        guard let data = UserDefaults.standard.data(forKey: "TestSessions"),
              let sessions = try? JSONDecoder().decode([TestSession].self, from: data) else {
            return []
        }
        return sessions
    }
}

// MARK: - Delegates
extension VoiceRecordingManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("Speech recognizer availability: \(available)")
    }
}

extension VoiceRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished successfully: \(flag)")
    }
}

// 保持数据模型不变...
struct TestSession: Identifiable, Codable {
    let id = UUID()
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    let startTime: Date
    var endTime: Date?
    var recordingSegments: [RecordingSegment] = []
}

struct RecordingSegment: Identifiable, Codable {
    let id: UUID
    let segmentNumber: Int
    let fileName: String
    let fileURL: URL
    let startTime: Date
    let endTime: Date
    let vin: String
    let testExecutionId: String
    let tag: String
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
} 