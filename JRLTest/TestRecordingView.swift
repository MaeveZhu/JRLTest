import SwiftUI
import AVFoundation
import CoreLocation

struct TestRecordingView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let milesBefore: Int
    @Binding var milesAfter: Int
    @Binding var showingResultsView: Bool
    
    @StateObject private var voiceTriggerManager = VoiceTriggerManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var recordingManager = RecordingManager()
    @StateObject private var audioPlayer = AudioPlayer()
    
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    @State private var showingPlaybackView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 测试信息显示
                VStack(spacing: 10) {
                    Text("Test Case: \(tag)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("VIN: \(vin)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Execution ID: \(testExecutionId)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // 状态显示
                VStack(spacing: 15) {
                    // GPS状态
                    HStack {
                        Image(systemName: locationStatusIcon)
                            .foregroundColor(locationStatusColor)
                        Text(locationStatusText)
                            .font(.caption)
                    }
                    
                    // 语音识别状态
                    HStack {
                        Image(systemName: voiceStatusIcon)
                            .foregroundColor(voiceStatusColor)
                        Text(voiceStatusText)
                            .font(.caption)
                    }
                    
                    // 录音状态
                    if isRecording {
                        HStack {
                            Image(systemName: "record.circle.fill")
                                .foregroundColor(.red)
                                .scaleEffect(1.2)
                            Text("录音中: \(recordingManager.formatDuration(recordingManager.recordingDuration))")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // 主要录音按钮
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 250, height: 250)
                        .shadow(radius: 10)
                    
                    VStack(spacing: 10) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text(buttonText)
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isRecording && canStartRecording {
                                startRecording()
                            }
                        }
                        .onEnded { _ in
                            if isRecording {
                                stopRecording()
                            }
                        }
                )
                
                Spacer()
                
                // 语音识别文本显示
                if !voiceTriggerManager.recognizedText.isEmpty {
                    VStack {
                        Text("识别到:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(voiceTriggerManager.recognizedText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // 底部按钮
                HStack(spacing: 20) {
                    Button(voiceTriggerManager.isListening ? "停止监听" : "开始监听") {
                        toggleVoiceListening()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(voiceTriggerManager.isListening ? .red : .blue)
                    
                    if recordedAudioURL != nil {
                        Button("播放录音") {
                            showingPlaybackView = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.green)
                    }
                    
                    Button("完成测试") {
                        showingResultsView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recordedAudioURL == nil)
                }
                .padding(.bottom)
            }
            .navigationTitle("Test Recording")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupPermissions()
            }
            .alert("权限请求", isPresented: $showingPermissionAlert) {
                Button("确定") { }
            } message: {
                Text(permissionAlertMessage)
            }
            .sheet(isPresented: $showingPlaybackView) {
                if let url = recordedAudioURL {
                    AudioPlaybackView(audioURL: url)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canStartRecording: Bool {
        guard let location = locationManager.currentLocation else { return false }
        return locationManager.authorizationStatus == .authorizedWhenInUse
    }
    
    private var buttonColor: Color {
        if isRecording {
            return .red
        } else if voiceTriggerManager.triggerDetected {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var buttonIcon: String {
        if isRecording {
            return "stop.circle.fill"
        } else if voiceTriggerManager.triggerDetected {
            return "mic.circle.fill"
        } else {
            return "mic.circle"
        }
    }
    
    private var buttonText: String {
        if isRecording {
            return "松开停止录音"
        } else if voiceTriggerManager.triggerDetected {
            return "语音触发！\n点击开始录音"
        } else {
            return "按住录音\n或说\"开始记录\""
        }
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
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.locationStatus {
        case .available:
            return .green
        case .denied, .error:
            return .red
        case .unknown:
            return .orange
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.locationStatus {
        case .available:
            if let location = locationManager.currentLocation {
                return String(format: "GPS: %.6f, %.6f", location.latitude, location.longitude)
            } else {
                return "GPS: 获取中..."
            }
        case .denied:
            return "GPS: 权限被拒绝"
        case .error(let message):
            return "GPS: \(message)"
        case .unknown:
            return "GPS: 未知状态"
        }
    }
    
    private var voiceStatusIcon: String {
        if voiceTriggerManager.isListening {
            return "mic.fill"
        } else {
            return "mic.slash"
        }
    }
    
    private var voiceStatusColor: Color {
        if voiceTriggerManager.isListening {
            return .green
        } else {
            return .gray
        }
    }
    
    private var voiceStatusText: String {
        if voiceTriggerManager.isListening {
            return "语音监听: 开启"
        } else {
            return "语音监听: 关闭"
        }
    }
    
    // MARK: - Methods
    
    private func setupPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            locationManager.requestLocationPermission()
            
            voiceTriggerManager.requestPermissions { granted in
                if granted {
                    print("语音识别权限已获取")
                } else {
                    DispatchQueue.main.async {
                        permissionAlertMessage = "需要语音识别权限才能使用语音触发功能"
                        showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    private func toggleVoiceListening() {
        if voiceTriggerManager.isListening {
            voiceTriggerManager.stopListening()
        } else {
            do {
                try voiceTriggerManager.startListening()
            } catch {
                permissionAlertMessage = "启动语音监听失败: \(error.localizedDescription)"
                showingPermissionAlert = true
            }
        }
    }
    
    private func startRecording() {
        guard let coordinate = locationManager.currentLocation else {
            permissionAlertMessage = "无法获取GPS位置，请检查定位权限"
            showingPermissionAlert = true
            return
        }
        
        if recordingManager.startRecording(at: coordinate) {
            isRecording = true
            voiceTriggerManager.resetTrigger()
        } else {
            permissionAlertMessage = "启动录音失败，请检查麦克风权限"
            showingPermissionAlert = true
        }
    }
    
    private func stopRecording() {
        if let recordingURL = recordingManager.stopRecording() {
            isRecording = false
            recordedAudioURL = recordingURL
            print("录音已保存: \(recordingURL)")
        }
    }
}

struct TestRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        TestRecordingView(
            vin: "TEST123",
            testExecutionId: "EXEC001",
            tag: "Engine Test",
            milesBefore: 138,
            milesAfter: .constant(160),
            showingResultsView: .constant(false)
        )
    }
} 
