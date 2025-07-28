import SwiftUI
import AVFoundation

struct SimpleTestRecordingView: View {
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("录音测试")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 录音状态
            if isRecording {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .scaleEffect(1.2)
                    Text("录音中: \(recordingDuration)")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            // 录音按钮
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                VStack(spacing: 10) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(isRecording ? "停止录音" : "开始录音")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 300, height: 300)
                .background(isRecording ? Color.red : Color.blue)
                .cornerRadius(150)
                .shadow(radius: 10)
            }
            
            Spacer()
            
            // 测试说明
            VStack(spacing: 10) {
                Text("测试说明:")
                    .font(.headline)
                Text("1. 点击蓝色按钮开始录音")
                Text("2. 按钮变红色表示正在录音")
                Text("3. 再次点击停止录音")
                Text("4. 录音文件会保存到Documents/Recordings目录")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .alert("录音状态", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var recordingDuration: String {
        guard let startTime = recordingStartTime else { return "00:00" }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startRecording() {
        print("=== 开始录音测试 ===")
        
        // 检查麦克风权限
        let permissionStatus = AVAudioApplication.shared.recordPermission
        print("麦克风权限状态: \(permissionStatus.rawValue)")
        
        if permissionStatus != .granted {
            print("请求麦克风权限")
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startRecording()
                    } else {
                        self.alertMessage = "麦克风权限被拒绝"
                        self.showingAlert = true
                    }
                }
            }
            return
        }
        
        // 设置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // 创建录音文件URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsPath = documentsPath.appendingPathComponent("Recordings")
            
            // 创建Recordings目录（如果不存在）
            if !FileManager.default.fileExists(atPath: recordingsPath.path) {
                try FileManager.default.createDirectory(at: recordingsPath, withIntermediateDirectories: true)
            }
            
            let fileName = "simple_test_recording_\(Date().timeIntervalSince1970).m4a"
            let fileURL = recordingsPath.appendingPathComponent(fileName)
            
            // 录音设置
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // 创建录音器
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = nil
            audioRecorder?.record()
            
            // 更新状态
            isRecording = true
            recordingStartTime = Date()
            
            print("✅ 录音开始: \(fileURL)")
            alertMessage = "录音已开始"
            showingAlert = true
            
        } catch {
            print("❌ 录音启动失败: \(error)")
            alertMessage = "录音启动失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func stopRecording() {
        print("=== 停止录音测试 ===")
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingStartTime = nil
        
        print("✅ 录音已停止")
        alertMessage = "录音已停止并保存"
        showingAlert = true
    }
}

struct SimpleTestRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleTestRecordingView()
    }
} 