import Foundation
import AVFoundation
import Intents
import CoreLocation
import Speech

@available(iOS 12.0, *)
class UnifiedAudioManager: NSObject, ObservableObject {
    static let shared = UnifiedAudioManager()
    
    @Published var isRecording = false
    @Published var isListening = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var errorMessage: String?
    @Published var currentTestSession: TestSession?
    @Published var recordingSegments: [RecordingSegment] = []
    @Published var isPlaying = false
    @Published var currentPlaybackURL: URL?
    @Published var playbackProgress: TimeInterval = 0
    @Published var recognizedSpeech: String = ""
    @Published var isRecognizingSpeech = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?
    private var playbackTimer: Timer?
    private var audioLevelTimer: Timer?
    private var currentSegmentNumber = 1
    private let maxRecordingDuration: TimeInterval = 180
    private let silenceDetectionDuration: TimeInterval = 10  // Changed from 5 to 10 seconds
    private var currentSegmentStartCoordinate: CLLocationCoordinate2D?
    
    // Audio Engine for Speech Recognition
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    private let permissionManager = PermissionManager.shared
    private var locationManager: LocationManager?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override init() {
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupSiriKit()
            self.setupAudioSession()
        }
    }
    
    deinit {
        stopAllAudio()
    }
    
    private func setupSiriKit() {
        let currentStatus = INPreferences.siriAuthorizationStatus()
        
        if currentStatus == .authorized {
            self.isListening = true
        } else {
            permissionManager.requestSiriPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.isListening = true
                    } else {
                        self?.errorMessage = "Siri权限未授权，请在设置中启用"
                    }
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            errorMessage = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    func startSiriDrivingTest() {
        let siriStatus = INPreferences.siriAuthorizationStatus()
        guard siriStatus == .authorized else {
            errorMessage = "Siri权限未授权，请在设置中启用"
            return
        }
        
        guard permissionManager.allPermissionsGranted else {
            errorMessage = permissionManager.getMissingPermissionsMessage()
            return
        }
        
        currentTestSession = TestSession(
            operatorCDSID: "SIRI_TEST",
            driverCDSID: UUID().uuidString,
            testExecution: UUID().uuidString,
            testProcedure: "SiriKit Test",
            testType: "SiriKit Test",
            testNumber: 1,
            startCoordinate: nil,
            startTime: Date()
        )
        recordingSegments = []
        currentSegmentNumber = 1
        
        startRecording()
    }
    
    // ... existing code ...
func startRecording() {
    guard !isRecording else { return }
    
    do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
        
        let fileName = "siri_segment_\(currentSegmentNumber)_\(Date().timeIntervalSince1970).m4a"
        let recordingsURL = try createRecordingsDirectory()
        let fileURL = recordingsURL.appendingPathComponent(fileName)
        
        // Use more compatible audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        
        recordingStartTime = Date()
        isRecording = true
        currentRecordingURL = fileURL
        
        currentSegmentStartCoordinate = getCurrentLocation()
        
        startRecordingTimer()
        
        startAudioLevelMonitoring()
        
        startSilenceDetection()
        
        // Start speech recognition immediately
        setupSpeechRecognition()
        startSpeechRecognition()
        
    } catch {
        errorMessage = "录音启动失败: \(error.localizedDescription)"
        print("❌ Recording start error: \(error)")
    }
}
// ... existing code ...
    
    func stopRecording() {
        guard isRecording, let recorder = audioRecorder else { 
            return 
        }
        
        // Stop speech recognition first
        stopSpeechRecognition()
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        stopAudioLevelMonitoring()
        
        recorder.stop()
        stopRecordingTimer()
        
        if let startTime = recordingStartTime, let session = currentTestSession {
            let currentSegmentEndCoordinate = getCurrentLocation()
            
            // Use recognized speech or indicate nothing was detected
            let speechText = recognizedSpeech.isEmpty ? "Nothing is detected" : recognizedSpeech
            print("🎤 Final recognized speech: \(speechText)")
            
            let segment = RecordingSegment(
                id: UUID(),
                segmentNumber: currentSegmentNumber,
                fileName: recorder.url.lastPathComponent,
                fileURL: recorder.url,
                startTime: startTime,
                endTime: Date(),
                operatorCDSID: session.operatorCDSID,
                driverCDSID: session.driverCDSID,
                testExecution: session.testExecution,
                testProcedure: session.testProcedure,
                testType: session.testType,
                testNumber: session.testNumber,
                startCoordinate: currentSegmentStartCoordinate,
                endCoordinate: currentSegmentEndCoordinate,
                recognizedSpeech: speechText
            )
            recordingSegments.append(segment)
            
            // Create a new session instance with updated recording segments
            var updatedSession = session
            updatedSession.recordingSegments = recordingSegments
            currentTestSession = updatedSession
            
            currentSegmentNumber += 1
            
            listRecordingsDirectory()
        } else {
            // Failed to create recording segment
        }
        
        audioRecorder = nil
        recordingStartTime = nil
        isRecording = false
        recordingDuration = 0
        recognizedSpeech = ""
        
        // Properly deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ Audio session deactivated")
        } catch {
            print("❌ Error deactivating audio session: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isListening = true
        }
    }
    
    private func startSilenceDetection() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDetectionDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopRecordingAndReturnToListening()
            }
        }
    }
    
    private func stopAllAudio() {
        if isRecording {
            audioRecorder?.stop()
            audioRecorder = nil
            isRecording = false
        }
        
        if isPlaying {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying = false
            currentPlaybackURL = nil
            playbackProgress = 0
        }
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        stopRecordingTimer()
        stopPlaybackTimer()
        stopSpeechRecognition()
        isListening = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // Error deactivating audio session
        }
        
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func createRecordingsDirectory() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsURL = documentsPath.appendingPathComponent("SiriRecordings")
        if !FileManager.default.fileExists(atPath: recordingsURL.path) {
            try FileManager.default.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
        }
        return recordingsURL
    }
    
    private func listRecordingsDirectory() {
        // Debug method - can be removed in production
    }
    
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
                        operatorCDSID: segment.operatorCDSID,
                        driverCDSID: segment.driverCDSID,
                        testExecution: segment.testExecution,
                        testProcedure: segment.testProcedure,
                        testType: segment.testType,
                        testNumber: segment.testNumber,
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
    
    func endTestSession() {
        if isRecording { 
            stopRecording() 
        }
        
        if let session = currentTestSession {
            // Create a new session instance with updated recording segments
            var updatedSession = session
            updatedSession.recordingSegments = recordingSegments
            updatedSession.endTime = Date()
            updatedSession.endCoordinate = getCurrentLocation()
            
            let sessions = getTestSessions()
            var updatedSessions = sessions
            updatedSessions.append(updatedSession)
            
            if let data = try? JSONEncoder().encode(updatedSessions) {
                UserDefaults.standard.set(data, forKey: "testSessions")
            }
        }
        
        // Clean up
        currentTestSession = nil
        recordingSegments = []
        currentSegmentNumber = 1
        isListening = false
        
        // Stop all audio operations
        stopAllAudio()
        
        // Post notification for UI update
        NotificationCenter.default.post(name: NSNotification.Name("TestSessionEnded"), object: nil)
    }
    
    func checkPermissions() -> Bool {
        return permissionManager.allPermissionsGranted
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        permissionManager.requestAllPermissions(completion: completion)
    }
    
    func getPermissionStatus() -> String {
        return permissionManager.permissionStatusDescription
    }
    
    func openSettings() {
        permissionManager.openSettings()
    }
    
    func startTestSession(operatorCDSID: String, driverCDSID: String, testExecution: String, testProcedure: String, testType: String, testNumber: Int, startCoordinate: CLLocationCoordinate2D?) {
        currentTestSession = TestSession(
            operatorCDSID: operatorCDSID,
            driverCDSID: driverCDSID,
            testExecution: testExecution,
            testProcedure: testProcedure,
            testType: testType,
            testNumber: testNumber,
            startCoordinate: startCoordinate,
            startTime: Date()
        )
        recordingSegments = []
        currentSegmentNumber = 1
        
        NotificationCenter.default.post(
            name: NSNotification.Name("TestSessionStarted"),
            object: currentTestSession
        )
    }
    
    func startListening() {
        isListening = true
    }
    
    func stopListening() {
        isListening = false
    }
    
    func startRecordingWithCoordinate() {
        guard !isRecording else {
            return
        }
        
        guard permissionManager.allPermissionsGranted else {
            errorMessage = permissionManager.getMissingPermissionsMessage()
            
            permissionManager.requestAllPermissions { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startRecordingWithCoordinate()
                    } else {
                        // Still missing permissions after request
                    }
                }
            }
            return
        }
        
        startRecording()
        
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopRecordingAndReturnToListening()
            }
        }
    }
    
    private func stopRecordingAndReturnToListening() {
        stopRecording()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isListening = true
        }
    }
    
// ... existing code ...
private func verifyAudioFile(_ url: URL) -> Bool {
    let exists = FileManager.default.fileExists(atPath: url.path)
    if exists {
        print("✅ Audio file exists: \(url.lastPathComponent)")
        
        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                print("📁 File size: \(fileSize) bytes")
                if fileSize == 0 {
                    print("❌ File is empty")
                    return false
                }
            }
        } catch {
            print("❌ Error checking file attributes: \(error)")
            return false
        }
        
        return true
    } else {
        print("❌ Audio file missing: \(url.path)")
        return false
    }
}

func playAudioFile(at url: URL) {
    guard verifyAudioFile(url) else {
        errorMessage = "音频文件不存在或为空: \(url.lastPathComponent)"
        return
    }
    
    stopPlayback()
    
    do {
        // Configure audio session for playback
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create audio player with error handling
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        
        // Check if audio player is valid
        guard let player = audioPlayer, player.duration > 0 else {
            errorMessage = "音频文件格式不支持或已损坏"
            print("❌ Invalid audio file: duration = \(audioPlayer?.duration ?? 0)")
            return
        }
        
        player.prepareToPlay()
        
        // Start playback
        if player.play() {
            isPlaying = true
            currentPlaybackURL = url
            playbackProgress = 0
            startPlaybackTimer()
            print("✅ Audio playback started: \(url.lastPathComponent), duration: \(player.duration)")
        } else {
            errorMessage = "音频播放启动失败"
            print("❌ Failed to start audio playback")
        }
        
    } catch {
        errorMessage = "音频播放失败: \(error.localizedDescription)"
        print("❌ Audio playback error: \(error)")
        
        // Try to get more specific error information
        if let nsError = error as NSError? {
            print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
            print("❌ Error description: \(nsError.localizedDescription)")
        }
    }
}


    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentPlaybackURL = nil
        playbackProgress = 0
        stopPlaybackTimer()
    }
    
    func isPlaying(_ url: URL) -> Bool {
        return isPlaying && currentPlaybackURL == url
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = self.audioPlayer {
                self.playbackProgress = player.currentTime
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func setLocationManager(_ locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    private func getCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager?.currentLocation
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkAudioLevel()
        }
    }

    private func checkAudioLevel() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        
        let averageLevel = pow(10.0, averagePower / 20.0)
        let peakLevel = pow(10.0, peakPower / 20.0)
        
        // More sensitive threshold for voice detection
        if averageLevel > 0.0005 || peakLevel > 0.005 {
            resetSilenceTimer()
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDetectionDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopRecordingAndReturnToListening()
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    // MARK: - Speech Recognition
    
    private func setupSpeechRecognition() {
        // Check speech recognition permission first
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .authorized:
            break
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.setupSpeechRecognizer()
                    } else {
                        self?.errorMessage = "语音识别权限被拒绝"
                        print("❌ Speech recognition permission denied")
                    }
                }
            }
            return
        case .denied, .restricted:
            errorMessage = "语音识别权限未授权"
            print("❌ Speech recognition permission not granted: \(speechStatus.rawValue)")
            return
        @unknown default:
            errorMessage = "语音识别权限未知状态"
            return
        }
        
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        // Try Chinese first, then fallback to English
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        if speechRecognizer == nil || !speechRecognizer!.isAvailable {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            print("❌ Speech recognition not available")
            return
        }
        
        speechRecognizer.delegate = self
        print("🎤 Speech recognition setup completed with locale: \(speechRecognizer.locale.identifier)")
    }
    
    private func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ Speech recognition not available")
            return
        }
        
        // Ensure audio session is properly configured
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to configure audio session for speech recognition: \(error)")
            return
        }
        
        // Set up audio engine for speech recognition
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else {
            print("❌ Failed to set up audio engine")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Failed to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Install tap on input node with compatible format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎤 Using recording format: \(recordingFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
            print("✅ Audio engine started for speech recognition")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Speech recognition error: \(error)")
                    return
                }
                
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    if !recognizedText.isEmpty {
                        self?.recognizedSpeech = recognizedText
                        print("🎤 Recognized speech: \(recognizedText)")
                    }
                    
                    if result.isFinal {
                        print("✅ Speech recognition completed")
                        self?.stopSpeechRecognition()
                    }
                }
            }
        }
        
        isRecognizingSpeech = true
        print("🎤 Speech recognition started")
    }
    
    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizingSpeech = false
        
        // Stop audio engine if it was started
        if let audioEngine = audioEngine {
            audioEngine.stop()
            inputNode?.removeTap(onBus: 0)
            print("🛑 Audio engine stopped")
        }
        audioEngine = nil
        inputNode = nil
        
        print("🛑 Speech recognition stopped")
    }
    
    private func updateSpeechRecognitionWithAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
    
    func getSpeechRecognitionStatus() -> String {
        guard let speechRecognizer = speechRecognizer else {
            return "语音识别未初始化"
        }
        
        if speechRecognizer.isAvailable {
            return "语音识别可用"
        } else {
            return "语音识别不可用"
        }
    }
    
    func isSpeechRecognitionAvailable() -> Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    // Method to manually test speech recognition
    func testSpeechRecognition() {
        print("🎤 Testing speech recognition...")
        setupSpeechRecognition()
        startSpeechRecognition()
    }

    // Legacy method for backward compatibility
    func startTestSession(vin: String, testExecutionId: String, tag: String, startCoordinate: CLLocationCoordinate2D?) {
        startTestSession(
            operatorCDSID: vin,
            driverCDSID: testExecutionId,
            testExecution: testExecutionId,
            testProcedure: "Legacy Test",
            testType: tag,
            testNumber: 1,
            startCoordinate: startCoordinate
        )
    }
}

@available(iOS 12.0, *)
extension UnifiedAudioManager: AVAudioRecorderDelegate {
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

@available(iOS 12.0, *)
extension UnifiedAudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentPlaybackURL = nil
            self.playbackProgress = 0
            self.stopPlaybackTimer()
            
            if !flag {
                self.errorMessage = "音频播放完成但可能存在问题"
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "音频解码错误: \(error.localizedDescription)"
            }
            self.isPlaying = false
            self.currentPlaybackURL = nil
        }
    }
}

@available(iOS 12.0, *)
extension UnifiedAudioManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "语音识别服务不可用"
            }
        }
    }
}

 
