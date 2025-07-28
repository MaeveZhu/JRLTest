import SwiftUI
import AVFoundation

struct SimpleVoiceRecordView: View {
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var recordings: [URL] = []
    
    var body: some View {
        VStack(spacing: 30) {
            Text("语音录音")
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
                print("录音按钮被点击")
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
            
            // 录音列表按钮
            Button(action: {
                print("录音列表按钮被点击")
                loadRecordings()
                showingAlert = true
                alertMessage = "录音文件数量: \(recordings.count)"
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                    Text("录音列表 (\(recordings.count))")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
        .padding()
        .alert("录音状态", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadRecordings()
        }
    }
    
    private var recordingDuration: String {
        guard let startTime = recordingStartTime else { return "00:00" }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil)
            recordings = files.filter { $0.pathExtension == "m4a" }
            print("加载录音列表: \(recordings.count) 个录音文件")
        } catch {
            print("加载录音列表失败: \(error.localizedDescription)")
            recordings = []
        }
    }
    
    private func startRecording() {
        print("=== 开始录音函数被调用 ===")
        
        // 检查麦克风权限
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        print("麦克风权限状态: \(permissionStatus.rawValue)")
        
        if permissionStatus != .granted {
            print("请求麦克风权限")
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("麦克风权限已获取，重新尝试录音")
                        self.startRecording()
                    } else {
                        print("麦克风权限被拒绝")
                        self.alertMessage = "麦克风权限被拒绝"
                        self.showingAlert = true
                    }
                }
            }
            return
        }
        
        do {
            // 设置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // 创建录音文件路径
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)
            
            // 创建Recordings目录（如果不存在）
            if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
                try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
            }
            
            let recordingName = "recording_\(Date().timeIntervalSince1970).m4a"
            let audioFilename = recordingsDirectory.appendingPathComponent(recordingName)
            
            print("录音文件路径: \(audioFilename)")
            
            // 录音设置
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // 创建录音器
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            
            // 开始录音
            if audioRecorder?.record() == true {
                isRecording = true
                recordingStartTime = Date()
                print("✅ 录音开始成功")
                alertMessage = "录音开始成功"
                showingAlert = true
            } else {
                print("❌ 录音开始失败")
                alertMessage = "录音开始失败"
                showingAlert = true
            }
        } catch {
            print("❌ 录音设置失败: \(error.localizedDescription)")
            alertMessage = "录音设置失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func stopRecording() {
        print("=== 停止录音函数被调用 ===")
        
        audioRecorder?.stop()
        
        if let url = audioRecorder?.url {
            print("✅ 录音已保存: \(url)")
            alertMessage = "录音已保存: \(url.lastPathComponent)"
            loadRecordings() // 重新加载录音列表
        } else {
            print("❌ 录音保存失败")
            alertMessage = "录音保存失败"
        }
        
        isRecording = false
        recordingStartTime = nil
        audioRecorder = nil
        showingAlert = true
    }
} 
