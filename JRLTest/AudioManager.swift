import Foundation
import AVFoundation
import CoreLocation

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playbackProgress: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var recordingStartTime: Date?
    private var isProcessingRecording = false
    
    // MARK: - Audio Session
    private var audioSession: AVAudioSession {
        return AVAudioSession.sharedInstance()
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Audio session setup failed: \(error.localizedDescription)")
            errorMessage = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Permission Management
    func checkMicrophonePermission() -> Bool {
        let permission = AVAudioApplication.shared.recordPermission
        return permission == .granted
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let currentPermission = AVAudioApplication.shared.recordPermission
        
        switch currentPermission {
        case .granted:
            completion(true)
        case .denied:
            errorMessage = "麦克风权限被拒绝，请在设置中启用"
            completion(false)
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(true)
                    } else {
                        self.errorMessage = "麦克风权限被拒绝"
                        completion(false)
                    }
                }
            }
        @unknown default:
            errorMessage = "未知的麦克风权限状态"
            completion(false)
        }
    }
    
    // MARK: - Recording Functions
    func startRecording(at coordinate: CLLocationCoordinate2D? = nil) -> Bool {
        print("=== AudioManager.startRecording 被调用 ===")
        
        guard !isProcessingRecording else {
            errorMessage = "录音操作正在进行中，请稍后再试"
            return false
        }
        
        isProcessingRecording = true
        
        // Check permissions first
        guard checkMicrophonePermission() else {
            errorMessage = "麦克风权限未授权"
            isProcessingRecording = false
            return false
        }
        
        // Setup audio session
        setupAudioSession()
        
        do {
            // Create recordings directory
            let recordingsURL = try createRecordingsDirectory()
            
            // Generate filename with timestamp and coordinate
            let filename = generateRecordingFilename(coordinate: coordinate)
            let fileURL = recordingsURL.appendingPathComponent(filename)
            
            // Audio recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]
            
            // Create and configure recorder
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            // Start recording
            if audioRecorder?.record() == true {
                isRecording = true
                recordingStartTime = Date()
                currentRecordingURL = fileURL
                recordingDuration = 0
                errorMessage = nil
                
                // Start duration timer
                startRecordingTimer()
                
                print("✅ Recording started successfully: \(fileURL)")
                isProcessingRecording = false
                return true
            } else {
                errorMessage = "无法开始录音"
                isProcessingRecording = false
                return false
            }
            
        } catch {
            errorMessage = "录音设置失败: \(error.localizedDescription)"
            isProcessingRecording = false
            print("❌ Recording setup failed: \(error)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        print("=== AudioManager.stopRecording 被调用 ===")
        
        guard isRecording else {
            print("❌ Not currently recording")
            return nil
        }
        
        // Stop recording
        audioRecorder?.stop()
        stopRecordingTimer()
        
        let recordingURL = currentRecordingURL
        
        // Reset recording state
        isRecording = false
        recordingDuration = 0
        recordingStartTime = nil
        audioRecorder = nil
        
        if let url = recordingURL {
            print("✅ Recording stopped: \(url)")
            
            // Save recording metadata if coordinate is available
            if let coordinate = extractCoordinateFromFilename(url.lastPathComponent) {
                saveRecordingMetadata(url: url, coordinate: coordinate)
            }
            
            return url
        }
        
        return nil
    }
    
    // MARK: - Playback Functions
    func startPlayback(url: URL) -> Bool {
        print("=== AudioManager.startPlayback 被调用 ===")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "音频文件不存在"
            return false
        }
        
        do {
            // Setup audio session for playback
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Create and configure player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Start playback
            if audioPlayer?.play() == true {
                isPlaying = true
                playbackProgress = 0
                errorMessage = nil
                
                // Start progress timer
                startPlaybackTimer()
                
                print("✅ Playback started successfully")
                return true
            } else {
                errorMessage = "无法开始播放"
                return false
            }
            
        } catch {
            errorMessage = "播放设置失败: \(error.localizedDescription)"
            print("❌ Playback setup failed: \(error)")
            return false
        }
    }
    
    func stopPlayback() {
        print("=== AudioManager.stopPlayback 被调用 ===")
        
        audioPlayer?.stop()
        stopPlaybackTimer()
        
        isPlaying = false
        playbackProgress = 0
        audioPlayer = nil
        
        print("✅ Playback stopped")
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        stopPlaybackTimer()
        isPlaying = false
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        startPlaybackTimer()
        isPlaying = true
    }
    
    // MARK: - File Management
    private func createRecordingsDirectory() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsURL = documentsPath.appendingPathComponent("Recordings")
        
        if !FileManager.default.fileExists(atPath: recordingsURL.path) {
            try FileManager.default.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
        }
        
        return recordingsURL
    }
    
    private func generateRecordingFilename(coordinate: CLLocationCoordinate2D?) -> String {
        let timestamp = Date().timeIntervalSince1970
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        if let coord = coordinate {
            return "recording_\(dateString)_\(String(format: "%.6f", coord.latitude))_\(String(format: "%.6f", coord.longitude)).m4a"
        } else {
            return "recording_\(dateString)_\(timestamp).m4a"
        }
    }
    
    private func extractCoordinateFromFilename(_ filename: String) -> CLLocationCoordinate2D? {
        // Extract coordinate from filename if it exists
        let components = filename.components(separatedBy: "_")
        if components.count >= 4 {
            let latString = components[components.count - 2]
            let lonString = components[components.count - 1].replacingOccurrences(of: ".m4a", with: "")
            
            if let lat = Double(latString), let lon = Double(lonString) {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        return nil
    }
    
    private func saveRecordingMetadata(url: URL, coordinate: CLLocationCoordinate2D) {
        let recordingInfo = RecordModel(
            filename: url.lastPathComponent,
            fileURL: url,
            coordinate: coordinate,
            duration: recordingDuration
        )
        
        // Save to UserDefaults or Core Data for persistence
        saveRecordingToUserDefaults(recordingInfo)
        
        print("✅ Recording metadata saved: \(recordingInfo.filename)")
    }
    
    func saveRecordingToUserDefaults(_ recording: RecordModel) {
        // This is a simple implementation using UserDefaults
        // In a production app, you might want to use Core Data instead
        var recordings = getRecordingsFromUserDefaults()
        recordings.append(recording)
        
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: "SavedRecordings")
        }
    }
    
    func getRecordingsFromUserDefaults() -> [RecordModel] {
        guard let data = UserDefaults.standard.data(forKey: "SavedRecordings"),
              let recordings = try? JSONDecoder().decode([RecordModel].self, from: data) else {
            return []
        }
        return recordings
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
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updatePlaybackProgress()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        playbackProgress = player.currentTime
    }
    
    // MARK: - Utility Functions
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func getCurrentPlaybackTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    func getTotalPlaybackTime() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    func seekToTime(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
        playbackProgress = time
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
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

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stopPlayback()
            if !flag {
                self.errorMessage = "播放完成但可能存在问题"
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "播放解码错误: \(error.localizedDescription)"
            }
        }
    }
} 