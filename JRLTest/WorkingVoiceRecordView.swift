import SwiftUI
import AVFoundation
import CoreLocation

struct WorkingVoiceRecordView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var recordingManager = RecordingManager()
    
    @State private var isRecording = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var recordingStartTime: Date?
    @State private var showingLocationPermissionAlert = false
    @State private var showingRecordingsList = false
    @State private var recordings: [RecordModel] = []
    
    var body: some View {
        VStack(spacing: 30) {
            // 状态显示
            VStack(spacing: 15) {
                // GPS状态
                HStack {
                    Image(systemName: locationStatusIcon)
                        .foregroundColor(locationStatusColor)
                    Text(locationStatusText)
                        .font(.caption)
                }
                
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
            }
            .padding()
            
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
                showingRecordingsList = true
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
        .navigationTitle("语音录音")
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            Button("确定") { }
        } message: {
            Text(permissionAlertMessage)
        }
        .alert("位置权限", isPresented: $showingLocationPermissionAlert) {
            Button("允许") {
                locationManager.requestLocationPermission()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要位置权限来记录录音时的GPS坐标")
        }
        .sheet(isPresented: $showingRecordingsList) {
            RecordingsListView(recordings: recordings)
        }
        .onAppear {
            // 延迟请求位置权限，避免启动时崩溃
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                locationManager.requestLocationPermission()
            }
            // 加载录音列表
            loadRecordings()
        }
    }
    
    private func loadRecordings() {
        let urls = FileManagerHelper.getAllRecordings()
        recordings = urls.compactMap { url in
            guard let coordinate = FileManagerHelper.parseCoordinateFromFilename(url.lastPathComponent) else {
                return nil
            }
            return RecordModel(
                filename: url.lastPathComponent,
                fileURL: url,
                coordinate: coordinate
            )
        }
        print("加载录音列表: \(recordings.count) 个录音文件")
    }
    
    private var recordingDuration: String {
        guard let startTime = recordingStartTime else { return "00:00" }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var locationStatusIcon: String {
        switch locationManager.locationStatus {
        case .available:
            return "location.fill"
        case .denied:
            return "location.slash"
        case .error:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.locationStatus {
        case .available:
            return .green
        case .denied:
            return .red
        case .error:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.locationStatus {
        case .available:
            return "GPS: 已授权"
        case .denied:
            return "GPS: 权限被拒绝"
        case .error(let message):
            return "GPS: \(message)"
        case .unknown:
            return "GPS: 未知状态"
        }
    }
    
    private func startRecording() {
        print("=== 开始录音函数被调用 ===")
        
        // 检查位置权限
        print("检查位置权限: \(locationManager.locationStatus)")
        if locationManager.locationStatus != .available {
            print("❌ 位置权限未授权，显示权限请求对话框")
            showingLocationPermissionAlert = true
            return
        }
        
        // 检查麦克风权限
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        print("麦克风权限状态: \(microphoneStatus.rawValue)")
        
        if microphoneStatus != .granted {
            print("❌ 麦克风权限未授权，请求权限")
            requestMicrophonePermission()
            return
        }
        
        guard let coordinate = locationManager.currentLocation else {
            print("❌ 无法获取GPS位置")
            permissionAlertMessage = "无法获取GPS位置，请检查定位权限"
            showingPermissionAlert = true
            return
        }
        
        print("✅ 权限检查通过，坐标: \(coordinate.latitude), \(coordinate.longitude)")
        print("开始调用 recordingManager.startRecording...")
        
        let success = recordingManager.startRecording(at: coordinate)
        print("recordingManager.startRecording 返回: \(success)")
        
        if success {
            isRecording = true
            recordingStartTime = Date()
            print("✅ 录音开始成功")
        } else {
            print("❌ 录音开始失败")
            permissionAlertMessage = "启动录音失败，请检查麦克风权限"
            showingPermissionAlert = true
        }
    }
    
    private func stopRecording() {
        print("停止录音函数被调用")
        
        if let recordingURL = recordingManager.stopRecording() {
            print("录音已保存: \(recordingURL)")
            // 重新加载录音列表
            loadRecordings()
        } else {
            print("录音停止失败")
        }
        
        isRecording = false
        recordingStartTime = nil
    }
    
    private func requestMicrophonePermission() {
        print("请求麦克风权限")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("麦克风权限已获取，重新尝试录音")
                    self.startRecording()
                } else {
                    print("麦克风权限被拒绝")
                    self.permissionAlertMessage = "麦克风权限被拒绝，无法进行录音"
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Recordings List View
struct RecordingsListView: View {
    let recordings: [RecordModel]
    
    var body: some View {
        NavigationView {
            List(recordings) { recording in
                VStack(alignment: .leading, spacing: 8) {
                    Text(recording.filename)
                        .font(.headline)
                    
                    Text("时间: \(recording.formattedTimestamp)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("位置: \(recording.coordinateString)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("时长: \(recording.formattedDuration) | 大小: \(recording.fileSize)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("录音列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // 关闭列表
                    }
                }
            }
        }
    }
} 