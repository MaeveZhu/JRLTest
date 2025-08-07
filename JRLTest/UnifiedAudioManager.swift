import Foundation
import AVFoundation
import Intents
import CoreLocation

@available(iOS 12.0, *)
class UnifiedAudioManager: NSObject, ObservableObject {
    static let shared = UnifiedAudioManager()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isListening = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var errorMessage: String?
    @Published var currentTestSession: TestSession?
    @Published var recordingSegments: [RecordingSegment] = []
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?
    private var currentSegmentNumber = 1
    private let maxRecordingDuration: TimeInterval = 180 // 3 minutes
    private let silenceDetectionDuration: TimeInterval = 5 // 5 seconds
    
    // MARK: - Permission Manager
    private let permissionManager = PermissionManager.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Delay setup to avoid startup crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupSiriKit()
            self.setupAudioSession()
        }
    }
    
    deinit {
        stopAllAudio()
    }
    
    // MARK: - SiriKit Setup
    private func setupSiriKit() {
        // Check current permission status first
        let currentStatus = INPreferences.siriAuthorizationStatus()
        
        if currentStatus == .authorized {
            print("✅ SiriKit already authorized")
            self.isListening = true
        } else {
            // Request permission if not already granted
            permissionManager.requestSiriPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ SiriKit authorized")
                        self?.isListening = true
                    } else {
                        print("❌ SiriKit not authorized")
                        self?.errorMessage = "Siri权限未授权，请在设置中启用"
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("✅ Audio session configured for SiriKit")
        } catch {
            print("❌ Audio session setup failed: \(error.localizedDescription)")
            errorMessage = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - SiriKit Driving Test
    func startSiriDrivingTest() {
        print("🎤 SiriKit: Starting driving test session")
        
        // Verify SiriKit permission before starting
        let siriStatus = INPreferences.siriAuthorizationStatus()
        guard siriStatus == .authorized else {
            errorMessage = "Siri权限未授权，请在设置中启用"
            print("❌ SiriKit: Siri permission not granted - \(siriStatus)")
            return
        }
        
        // Check other permissions before starting
        guard permissionManager.allPermissionsGranted else {
            errorMessage = permissionManager.getMissingPermissionsMessage()
            print("❌ SiriKit: Missing permissions - \(permissionManager.getMissingPermissionsMessage())")
            return
        }
        
        // Create test session
        currentTestSession = TestSession(
            vin: "SIRI_TEST",
            testExecutionId: UUID().uuidString,
            tag: "SiriKit Test",
            startCoordinate: nil,
            startTime: Date()
        )
        recordingSegments = []
        currentSegmentNumber = 1
        
        // Start recording
        startRecording()
    }
    
    func startRecording() {
        print("🎙️ UnifiedAudioManager: startRecording() called")
        print("🎙️ UnifiedAudioManager: Current state - isRecording: \(isRecording)")
        
        do {
            let fileName = "siri_segment_\(currentSegmentNumber)_\(Date().timeIntervalSince1970).m4a"
            let recordingsURL = try createRecordingsDirectory()
            let fileURL = recordingsURL.appendingPathComponent(fileName)
            
            print("🎙️ UnifiedAudioManager: Creating recording file: \(fileName)")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            recordingStartTime = Date()
            isRecording = true
            currentRecordingURL = fileURL
            
            // Start recording timer
            startRecordingTimer()
            
            // Start 5-second silence detection
            startSilenceDetection()
            
            print("✅ UnifiedAudioManager: Recording started successfully: \(fileName)")
        } catch {
            print("❌ UnifiedAudioManager: Recording failed: \(error)")
            errorMessage = "录音启动失败: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        print("🛑 UnifiedAudioManager: stopRecording() called")
        print("🛑 UnifiedAudioManager: Current state - isRecording: \(isRecording)")
        
        guard isRecording, let recorder = audioRecorder else { 
            print("⚠️ UnifiedAudioManager: Cannot stop recording - not currently recording or no recorder")
            return 
        }
        
        print("🛑 UnifiedAudioManager: Stopping recording...")
        
        // Stop timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        
        // Stop recording
        recorder.stop()
        stopRecordingTimer()
        
        // Create recording segment
        if let startTime = recordingStartTime, let session = currentTestSession {
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
            print("✅ UnifiedAudioManager: Recording segment \(segment.segmentNumber) saved")
        }
        
        // Reset recording state
        audioRecorder = nil
        recordingStartTime = nil
        isRecording = false
        recordingDuration = 0
        
        print("✅ UnifiedAudioManager: Recording stopped successfully")
        
        // Resume listening for next "Hey Siri, start driving test"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isListening = true
            print("🎤 UnifiedAudioManager: Listening for next 'Hey Siri, start driving test'")
        }
    }
    
    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDetectionDuration, repeats: false) { [weak self] _ in
            print("🔇 UnifiedAudioManager: 5-second silence detected")
            DispatchQueue.main.async {
                self?.stopRecordingAndReturnToListening()
            }
        }
    }
    
    private func stopAllAudio() {
        print("🛑 SiriKit: Stopping all audio operations")
        
        if isRecording {
            audioRecorder?.stop()
            audioRecorder = nil
            isRecording = false
        }
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        stopRecordingTimer()
        isListening = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Error deactivating audio session: \(error)")
        }
        
        print("✅ SiriKit: All audio operations stopped")
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
    
    // MARK: - Data Persistence
    func saveTestSession(_ session: TestSession) {
        var sessions = getTestSessions()
        sessions.append(session)
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "SiriTestSessions")
        }
    }
    
    func getTestSessions() -> [TestSession] {
        guard let data = UserDefaults.standard.data(forKey: "SiriTestSessions"),
              let sessions = try? JSONDecoder().decode([TestSession].self, from: data) else {
            return []
        }
        return sessions
    }
    
    func endTestSession(endCoordinate: CLLocationCoordinate2D?) -> TestSession? {
        guard var session = currentTestSession else { return nil }
        
        stopAllAudio()
        
        session.endCoordinate = endCoordinate
        session.endTime = Date()
        session.recordingSegments = recordingSegments
        
        saveTestSession(session)
        
        currentTestSession = nil
        recordingSegments = []
        currentSegmentNumber = 1
        
        print("✅ SiriKit test session ended")
        return session
    }
    
    // MARK: - Permission Management
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
        print("✅ UnifiedAudioManager: Test session started")
        
        // Post notification for SiriKit integration
        NotificationCenter.default.post(
            name: NSNotification.Name("TestSessionStarted"),
            object: currentTestSession
        )
    }
    
    func startListening() {
        isListening = true
        print("✅ UnifiedAudioManager: Started listening for voice commands")
    }
    
    func stopListening() {
        isListening = false
        print("🛑 UnifiedAudioManager: Stopped listening for voice commands")
    }
    
    func startRecordingWithCoordinate() {
        print("🎙️ UnifiedAudioManager: startRecordingWithCoordinate() called")
        
        // Check if already recording
        guard !isRecording else {
            print("⚠️ UnifiedAudioManager: Already recording, ignoring start request")
            return
        }
        
        // Check permissions
        guard permissionManager.allPermissionsGranted else {
            errorMessage = permissionManager.getMissingPermissionsMessage()
            print("❌ UnifiedAudioManager: Missing permissions")
            return
        }
        
        // Start recording with coordinate capture
        startRecording()
        
        // Set up 3-minute max duration timer
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            print("⏰ UnifiedAudioManager: 3-minute max duration reached")
            DispatchQueue.main.async {
                self?.stopRecordingAndReturnToListening()
            }
        }
        
        print("✅ UnifiedAudioManager: Recording started with coordinate capture and 3-minute timer")
    }
    
    private func stopRecordingAndReturnToListening() {
        print("🛑 UnifiedAudioManager: stopRecordingAndReturnToListening() called")
        
        // Stop recording
        stopRecording()
        
        // Return to listening mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isListening = true
            print("🎤 UnifiedAudioManager: Returned to listening mode")
        }
    }
    
    func startPlayback(url: URL) {
        // Implementation for audio playback
        print("✅ UnifiedAudioManager: Starting playback for \(url.lastPathComponent)")
    }
}

// MARK: - AVAudioRecorderDelegate
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

 
