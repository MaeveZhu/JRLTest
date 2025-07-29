import SwiftUI
import AVFoundation
import CoreLocation

struct TestRecordingView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let milesBefore: Int
    @Binding var milesAfter: Int
    let startCoordinate: CLLocationCoordinate2D?
    @Binding var showingResultsView: Bool
    
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var audioRecorder: AVAudioRecorder?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var endCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("录音测试")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 测试信息显示
                VStack(spacing: 10) {
                    Text("VIN: \(vin)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Test ID: \(testExecutionId)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Tag: \(tag)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let coord = startCoordinate {
                        Text("起始位置: \(String(format: "%.6f, %.6f", coord.latitude, coord.longitude))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // 录音状态
                if isRecording {
                    HStack {
                        Image(systemName: "record.circle.fill")
                            .foregroundColor(.red)
                            .scaleEffect(1.2)
                        Text("录音中: \(formatDuration(recordingDuration))")
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
                        
                        Text(isRecording ? "结束录音" : "开始录音")
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
                    Text("3. 点击'结束录音'停止录音")
                    Text("4. 系统将自动记录结束位置")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
            .navigationTitle("测试录音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .alert("录音状态", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isRecording, let startTime = recordingStartTime {
                recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
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
            
            let fileName = "driving_record_\(Date().timeIntervalSince1970).m4a"
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
            recordingDuration = 0
            
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
        
        // 记录结束GPS坐标
        endCoordinate = locationManager.currentLocation
        
        // 停止录音
        audioRecorder?.stop()
        let recordingURL = audioRecorder?.url
        audioRecorder = nil
        isRecording = false
        
        // 模拟更新里程
        milesAfter = milesBefore + Int.random(in: 1...50)
        
        // 保存记录
        if let url = recordingURL {
            saveRecord(fileURL: url)
        }
        
        recordingStartTime = nil
        
        print("✅ 录音已停止")
        alertMessage = "录音已停止并保存"
        showingAlert = true
        
        // 延迟显示结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingResultsView = true
            dismiss()
        }
    }
    
    private func saveRecord(fileURL: URL) {
        let record = RecordModel(
            filename: fileURL.lastPathComponent,
            fileURL: fileURL,
            vin: vin,
            testExecutionId: testExecutionId,
            tag: tag,
            milesBefore: milesBefore,
            milesAfter: milesAfter,
            startCoordinate: startCoordinate,
            endCoordinate: endCoordinate,
            duration: recordingDuration
        )
        
        // 获取现有记录
        var records: [RecordModel] = []
        if let data = UserDefaults.standard.data(forKey: "DrivingRecords"),
           let existingRecords = try? JSONDecoder().decode([RecordModel].self, from: data) {
            records = existingRecords
        }
        
        // 添加新记录
        records.append(record)
        
        // 保存到UserDefaults
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "DrivingRecords")
            print("✅ 行车记录已保存")
        }
    }
}

struct TestRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        TestRecordingView(
            vin: "TEST123",
            testExecutionId: "EXEC001",
            tag: "Engine Test",
            milesBefore: 100,
            milesAfter: .constant(120),
            startCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            showingResultsView: .constant(false)
        )
    }
} 
