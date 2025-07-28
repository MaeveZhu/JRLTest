import Foundation
import AVFoundation
import CoreLocation

class RecordingManager: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    
    private var recordingTimer: Timer?
    private var isAudioSessionConfigured = false
    
    override init() {
        super.init()
        // 延迟设置音频会话，避免启动时崩溃
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupAudioSession()
        }
    }
    
    private func setupAudioSession() {
        guard !isAudioSessionConfigured else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            isAudioSessionConfigured = true
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    func startRecording(at coordinate: CLLocationCoordinate2D) -> Bool {
        // 确保音频会话已配置
        setupAudioSession()
        
        let filename = FileManagerHelper.generateFilename(with: coordinate)
        let url = FileManagerHelper.recordingURL(filename: filename)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            currentRecordingURL = url
            isRecording = true
            recordingDuration = 0
            
            // 开始计时
            startRecordingTimer()
            
            return true
        } catch {
            print("录音启动失败: \(error)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        stopRecordingTimer()
        
        isRecording = false
        let url = currentRecordingURL
        currentRecordingURL = nil
        
        return url
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingDuration += 1.0
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension RecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("录音完成: \(recorder.url)")
        } else {
            print("录音失败")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("录音编码错误: \(error)")
        }
    }
} 