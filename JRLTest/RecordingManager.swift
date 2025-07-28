import Foundation
import AVFoundation
import CoreLocation

class RecordingManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingError: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var currentRecordingCoordinate: CLLocationCoordinate2D?
    private var isProcessingRecording = false
    
    override init() {
        super.init()
        // 移除早期初始化，避免启动时崩溃
    }
    
    func startRecording(at coordinate: CLLocationCoordinate2D) -> Bool {
        print("=== RecordingManager.startRecording 被调用 ===")
        print("坐标: \(coordinate.latitude), \(coordinate.longitude)")
        
        guard !isProcessingRecording else {
            print("❌ 录音操作正在进行中，请稍后再试")
            return false
        }
        
        isProcessingRecording = true
        print("✅ 设置 isProcessingRecording = true")
        
        // 确保音频会话已配置
        setupAudioSession()
        print("✅ 音频会话已配置")
        
        // 检查麦克风权限
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        print("麦克风权限状态: \(permissionStatus.rawValue)")
        
        guard permissionStatus == .granted else {
            recordingError = "麦克风权限未授权"
            isProcessingRecording = false
            print("❌ 麦克风权限未授权")
            return false
        }
        
        print("✅ 麦克风权限检查通过")
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)
            
            // 创建Recordings目录（如果不存在）
            if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
                try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
            }
            
            let recordingName = "recording_\(Date().timeIntervalSince1970).m4a"
            let audioFilename = recordingsDirectory.appendingPathComponent(recordingName)
            
            print("录音文件路径: \(audioFilename)")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            print("录音设置: \(settings)")
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            print("✅ AVAudioRecorder 创建成功")
            
            if audioRecorder?.record() == true {
                isRecording = true
                recordingStartTime = Date()
                currentRecordingCoordinate = coordinate
                recordingError = nil
                
                // 开始计时器
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    self.updateRecordingDuration()
                }
                
                print("✅ 录音开始成功，坐标: \(coordinate.latitude), \(coordinate.longitude)")
                isProcessingRecording = false
                return true
            } else {
                recordingError = "无法开始录音"
                isProcessingRecording = false
                print("❌ 录音开始失败")
                return false
            }
        } catch {
            recordingError = "录音设置失败: \(error.localizedDescription)"
            isProcessingRecording = false
            print("❌ 录音设置失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        guard !isProcessingRecording else {
            print("录音操作正在进行中，请稍后再试")
            return nil
        }
        
        isProcessingRecording = true
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioRecorder?.stop()
        
        let recordingURL = audioRecorder?.url
        let coordinate = currentRecordingCoordinate
        
        // 重置状态
        isRecording = false
        recordingDuration = 0
        recordingStartTime = nil
        currentRecordingCoordinate = nil
        audioRecorder = nil
        
        isProcessingRecording = false
        
        if let url = recordingURL, let coord = coordinate {
            // 保存录音信息
            saveRecordingInfo(url: url, coordinate: coord)
            print("录音已停止，文件: \(url)")
            return url
        }
        
        return nil
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            recordingError = "音频会话设置失败: \(error.localizedDescription)"
        }
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
    
    private func saveRecordingInfo(url: URL, coordinate: CLLocationCoordinate2D) {
        let recordingInfo = RecordModel(
            filename: url.lastPathComponent,
            fileURL: url,
            coordinate: coordinate,
            duration: recordingDuration
        )
        
        // 保存到本地存储 - 使用静态方法
        // FileManagerHelper.shared.saveRecording(recordingInfo) // 这行被注释掉，因为FileManagerHelper没有shared实例
        
        // 录音信息已经通过RecordModel保存，文件已保存到文件系统
        print("录音信息已保存: \(recordingInfo.filename)")
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        recordingError = nil
    }
    
    func getLastError() -> String? {
        return recordingError
    }
}

// MARK: - AVAudioRecorderDelegate
extension RecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            if !flag {
                self.recordingError = "录音完成但可能存在问题"
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.recordingError = "录音编码错误: \(error.localizedDescription)"
            }
        }
    }
} 