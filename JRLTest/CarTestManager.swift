import Foundation
import AVFoundation
import CoreLocation
import Speech

class CarTestManager: NSObject, ObservableObject {
    static let shared = CarTestManager()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var errorMessage: String?
    @Published var recognizedSpeech: String = ""
    @Published var isRecognizingSpeech = false
    
    // MARK: - Private Properties
    private var recorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var maxDurationTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 180 // 3 minutes
    
    // Audio Engine for Speech Recognition
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Location Manager
    private var locationManager: LocationManager?
    private var currentSegmentStartCoordinate: CLLocationCoordinate2D?
    
    // Test Session Management
    private var currentTestSession: TestSession?
    private var recordingSegments: [RecordingSegment] = []
    private var currentSegmentNumber = 1
    
    override init() {
        super.init()
        setupAudioSession()
        setupSpeechRecognition()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            errorMessage = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Speech Recognition Setup
    private func setupSpeechRecognition() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .authorized:
            setupSpeechRecognizer()
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.setupSpeechRecognizer()
                    } else {
                        self?.errorMessage = "语音识别权限被拒绝"
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "语音识别权限未授权"
        @unknown default:
            errorMessage = "语音识别权限未知状态"
        }
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        if speechRecognizer == nil || !speechRecognizer!.isAvailable {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }
        
        speechRecognizer.delegate = self
    }
    
    // MARK: - Recording Methods
    func startRecording() {
        guard !isRecording else { 
            print("🎯 startRecording: Already recording, ignoring call")
            return 
        }
        
        print("🎯 startRecording: Starting new recording session")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
            
            // Generate timestamp-based filename
            let timestamp = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestampString = dateFormatter.string(from: timestamp)
            let fileName = "recording_\(timestampString).m4a"
            
            let recordingsURL = try createRecordingsDirectory()
            let fileURL = recordingsURL.appendingPathComponent(fileName)
            
            // Audio recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]
            
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            
            recordingStartTime = Date()
            isRecording = true
            currentRecordingURL = fileURL
            currentSegmentStartCoordinate = getCurrentLocation()
            
            startRecordingTimer()
            startSpeechRecognition()
            
            // Start max duration timer (3 minutes)
            maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.stopRecording()
                }
            }
            
            print("✅ Recording started: \(fileName), segment: \(currentSegmentNumber)")
            
        } catch {
            errorMessage = "录音启动失败: \(error.localizedDescription)"
            print("❌ Recording start error: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording, let recorder = recorder else { 
            print("🎯 stopRecording: Not recording, ignoring call")
            return 
        }
        
        print("🎯 stopRecording: Stopping recording session")
        
        stopSpeechRecognition()
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        
        recorder.stop()
        stopRecordingTimer()
        
        if let startTime = recordingStartTime, let session = currentTestSession {
            let currentSegmentEndCoordinate = getCurrentLocation()
            
            let speechText = recognizedSpeech.isEmpty ? "Nothing is detected" : recognizedSpeech
            
            let segment = RecordingSegment(
                id: UUID(),
                segmentNumber: currentSegmentNumber,
                fileName: recorder.url.lastPathComponent,
                fileURL: recorder.url,
                startTime: startTime,
                endTime: Date(),
                startCoordinate: currentSegmentStartCoordinate,
                endCoordinate: currentSegmentEndCoordinate,
                recognizedSpeech: speechText
            )
            recordingSegments.append(segment)
            
            // Update session
            var updatedSession = session
            updatedSession.recordingSegments = recordingSegments
            currentTestSession = updatedSession
            
            currentSegmentNumber += 1
            
            print("✅ Recording stopped: \(recorder.url.lastPathComponent), segment \(currentSegmentNumber - 1) completed")
        }
        
        self.recorder = nil
        recordingStartTime = nil
        isRecording = false
        recordingDuration = 0
        recognizedSpeech = ""
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Error deactivating audio session: \(error)")
        }
    }
    
    // MARK: - Timer Management
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateRecordingDuration()
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Speech Recognition
    private func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            return
        }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error { return }
                
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    if !recognizedText.isEmpty {
                        self?.recognizedSpeech = recognizedText
                    }
                    
                    if result.isFinal {
                        self?.stopSpeechRecognition()
                    }
                }
            }
        }
        
        isRecognizingSpeech = true
    }
    
    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizingSpeech = false
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            inputNode?.removeTap(onBus: 0)
        }
        audioEngine = nil
        inputNode = nil
    }
    
    // MARK: - Test Session Management
    func startTestSession(startCoordinate: CLLocationCoordinate2D?) {
        currentTestSession = TestSession(
            startCoordinate: startCoordinate,
            startTime: Date()
        )
        recordingSegments = []
        currentSegmentNumber = 1
        
        NotificationCenter.default.post(
            name: NSNotification.Name("TestSessionStarted"),
            object: currentTestSession
        )
        
        print("✅ Test session started")
    }
    
    func getCurrentSegmentNumber() -> Int {
        return currentSegmentNumber
    }
    
    func endTestSession() {
        if isRecording { 
            stopRecording() 
        }
        
        if let session = currentTestSession {
            var updatedSession = session
            updatedSession.recordingSegments = recordingSegments
            updatedSession.endTime = Date()
            updatedSession.endCoordinate = getCurrentLocation()
            
            let sessions = getTestSessions()
            var updatedSessions = sessions
            updatedSessions.append(updatedSession)
            
            if let data = try? JSONEncoder().encode(updatedSessions) {
                UserDefaults.standard.set(data, forKey: "testSessions")
                print("✅ Saved \(recordingSegments.count) recording segments to UserDefaults")
            } else {
                print("❌ Failed to encode test sessions")
            }
        }
        
        currentTestSession = nil
        recordingSegments = []
        currentSegmentNumber = 1
        
        NotificationCenter.default.post(name: NSNotification.Name("TestSessionEnded"), object: nil)
        print("✅ Test session ended")
    }
    
    func getTestSessions() -> [TestSession] {
        guard let data = UserDefaults.standard.data(forKey: "testSessions"),
              let sessions = try? JSONDecoder().decode([TestSession].self, from: data) else {
            return []
        }
        
        return sessions.map { session in
            var updatedSession = session
            updatedSession.recordingSegments = session.recordingSegments.map { segment in
                var updatedSegment = segment
                if !FileManager.default.fileExists(atPath: segment.fileURL.path) {
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let recordingsURL = documentsPath.appendingPathComponent("SiriRecordings")
                    let reconstructedURL = recordingsURL.appendingPathComponent(segment.fileName)
                    updatedSegment = RecordingSegment(
                        id: segment.id,
                        segmentNumber: segment.segmentNumber,
                        fileName: segment.fileName,
                        fileURL: reconstructedURL,
                        startTime: segment.startTime,
                        endTime: segment.endTime,
                        startCoordinate: segment.startCoordinate,
                        endCoordinate: segment.endCoordinate,
                        recognizedSpeech: segment.recognizedSpeech
                    )
                }
                return updatedSegment
            }
            return updatedSession
        }
    }
    
    // MARK: - Location Management
    func setLocationManager(_ locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    private func getCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager?.currentLocation
    }
    
    // MARK: - File Management
    private func createRecordingsDirectory() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsURL = documentsPath.appendingPathComponent("SiriRecordings")
        if !FileManager.default.fileExists(atPath: recordingsURL.path) {
            try FileManager.default.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
        }
        return recordingsURL
    }
    
    func listRecordings() {
        do {
            let recordingsURL = try createRecordingsDirectory()
            let files = try FileManager.default.contentsOfDirectory(at: recordingsURL, includingPropertiesForKeys: nil)
            print("📁 Recordings directory contains \(files.count) files:")
            for file in files {
                print("📄 \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Error listing recordings: \(error)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension CarTestManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            if !flag {
                self.errorMessage = "录音完成但可能存在问题"
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "录音编码错误: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension CarTestManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "语音识别服务不可用"
            }
        }
    }
}
