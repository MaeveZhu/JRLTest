import SwiftUI
import CoreLocation
import AVFoundation // Added for AVAudioSession

struct VoiceRecordView: View {
    @StateObject private var voiceTriggerManager = VoiceTriggerManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var recordingManager = RecordingManager()
    
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showingRecordingsList = false
    @State private var isInitialized = false
    @State private var showingVoiceWakeupSettings = false
    @State private var isProcessingGesture = false
    @State private var showingLocationPermissionAlert = false
    @State private var showingMicrophonePermissionAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            statusDisplaySection
            Spacer()
            mainRecordingButton
            Spacer()
            voiceRecognitionSection
            bottomButtonsSection
        }
        .onReceive(voiceTriggerManager.$triggerDetected) { detected in
            if detected && !recordingManager.isRecording {
                safeStartRecording()
            }
        }
        .sheet(isPresented: $showingRecordingsList) {
            recordingsListView
        }
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            permissionAlertButtons
        } message: {
            permissionAlertMessageView
        }
        .alert("位置权限", isPresented: $showingLocationPermissionAlert) {
            locationPermissionAlertButtons
        } message: {
            locationPermissionAlertMessage
        }
        .alert("麦克风权限", isPresented: $showingMicrophonePermissionAlert) {
            microphonePermissionAlertButtons
        } message: {
            microphonePermissionAlertMessage
        }
    }
    
    // MARK: - View Components
    
    private var statusDisplaySection: some View {
        VStack(spacing: 15) {
            gpsStatusRow
            voiceStatusRow
            voiceWakeupStatusRow
            recordingStatusRow
        }
        .padding()
    }
    
    private var gpsStatusRow: some View {
        HStack {
            Image(systemName: locationStatusIcon)
                .foregroundColor(locationStatusColor)
            Text(locationStatusText)
                .font(.caption)
        }
    }
    
    private var voiceStatusRow: some View {
        HStack {
            Image(systemName: voiceStatusIcon)
                .foregroundColor(voiceStatusColor)
            Text(voiceStatusText)
                .font(.caption)
        }
    }
    
    private var voiceWakeupStatusRow: some View {
        Group {
            if voiceTriggerManager.isListening {
                HStack {
                    Image(systemName: "ear.fill")
                        .foregroundColor(.blue)
                    Text("语音唤醒: 已开启")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if voiceTriggerManager.confidence > 0 {
                        Text("置信度: \(Int(voiceTriggerManager.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var recordingStatusRow: some View {
        Group {
            if recordingManager.isRecording {
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
    }
    
    private var mainRecordingButton: some View {
        ZStack {
            Circle()
                .fill(buttonColor)
                .frame(width: 300, height: 300)
                .shadow(radius: 10)
            
            VStack(spacing: 10) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text(buttonText)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                voiceWakeupHint
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    handleGestureChanged()
                }
                .onEnded { _ in
                    handleGestureEnded()
                }
        )
        .disabled(isProcessingGesture)
    }
    
    private var voiceWakeupHint: some View {
        Group {
            if voiceTriggerManager.isListening && !recordingManager.isRecording {
                Text("说\"开始录音\"即可自动开始")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 5)
            }
        }
    }
    
    private var voiceRecognitionSection: some View {
        Group {
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
                        .animation(.easeInOut, value: voiceTriggerManager.recognizedText)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var bottomButtonsSection: some View {
        HStack(spacing: 30) {
            voiceWakeupToggleButton
            recordingsListButton
        }
    }
    
    private var voiceWakeupToggleButton: some View {
        Button(action: toggleVoiceListening) {
            VStack(spacing: 5) {
                Image(systemName: voiceTriggerManager.isListening ? "ear.slash" : "ear")
                    .font(.title2)
                Text(voiceTriggerManager.isListening ? "关闭语音唤醒" : "开启语音唤醒")
                    .font(.caption)
            }
            .foregroundColor(voiceTriggerManager.isListening ? .red : .blue)
        }
        .disabled(isProcessingGesture)
    }
    
    private var recordingsListButton: some View {
        Button(action: { showingRecordingsList = true }) {
            VStack(spacing: 5) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                Text("录音列表")
                    .font(.caption)
            }
            .foregroundColor(.green)
        }
        .disabled(isProcessingGesture)
    }
    
    private var recordingsListView: some View {
        Text("录音列表功能已移至简化版本")
            .navigationTitle("录音列表")
    }
    
    private var permissionAlertButtons: some View {
        Button("确定") { }
    }
    
    private var permissionAlertMessageView: some View {
        Text(permissionAlertMessage)
    }
    
    private var locationPermissionAlertButtons: some View {
        Group {
            Button("允许") {
                locationManager.requestLocationPermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var locationPermissionAlertMessage: some View {
        Text("需要位置权限来记录录音时的GPS坐标")
    }
    
    private var microphonePermissionAlertButtons: some View {
        Group {
            Button("允许") {
                requestMicrophonePermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var microphonePermissionAlertMessage: some View {
        Text("需要麦克风权限来进行语音录音和语音识别")
    }
    
    // MARK: - Safe Gesture Handling
    
    private func handleGestureChanged() {
        guard !isProcessingGesture else { return }
        
        DispatchQueue.main.async {
            isProcessingGesture = true
            
            if !recordingManager.isRecording && canStartRecording {
                safeStartRecording()
            }
        }
    }
    
    private func handleGestureEnded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if recordingManager.isRecording {
                safeStopRecording()
            }
            isProcessingGesture = false
        }
    }
    
    // MARK: - Safe Recording Methods
    
    private func safeStartRecording() {
        guard !recordingManager.isRecording else { return }
        
        DispatchQueue.main.async {
            startRecording()
        }
    }
    
    private func safeStopRecording() {
        guard recordingManager.isRecording else { return }
        
        DispatchQueue.main.async {
            stopRecording()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canStartRecording: Bool {
        locationManager.locationStatus == .available && 
        locationManager.currentLocation != nil
    }
    
    private var buttonColor: Color {
        if recordingManager.isRecording {
            return .red
        } else if voiceTriggerManager.isListening {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var buttonIcon: String {
        if recordingManager.isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var buttonText: String {
        if recordingManager.isRecording {
            return "停止录音"
        } else if voiceTriggerManager.isListening {
            return "点击录音\n或语音唤醒"
        } else {
            return "点击开始录音"
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
    
    private func startRecording() {
        // 检查位置权限
        if locationManager.locationStatus != .available {
            showingLocationPermissionAlert = true
            return
        }
        
        // 检查麦克风权限
        let microphoneStatus = AVAudioApplication.shared.recordPermission
        if microphoneStatus != .granted {
            showingMicrophonePermissionAlert = true
            return
        }
        
        guard let coordinate = locationManager.currentLocation else {
            permissionAlertMessage = "无法获取GPS位置，请检查定位权限"
            showingPermissionAlert = true
            return
        }
        
        if recordingManager.startRecording(at: coordinate) {
            voiceTriggerManager.resetTrigger()
        } else {
            permissionAlertMessage = "启动录音失败，请检查麦克风权限"
            showingPermissionAlert = true
        }
    }
    
    private func stopRecording() {
        if let recordingURL = recordingManager.stopRecording() {
            print("录音已保存: \(recordingURL)")
        }
    }
    
    private func toggleVoiceListening() {
        guard !isProcessingGesture else { return }
        
        DispatchQueue.main.async {
            if voiceTriggerManager.isListening {
                voiceTriggerManager.stopListening()
            } else {
                // 首先请求权限
                voiceTriggerManager.requestPermissions { granted in
                    if granted {
                        do {
                            try self.voiceTriggerManager.startListening()
                        } catch {
                            self.permissionAlertMessage = "启动语音监听失败: \(error.localizedDescription)"
                            self.showingPermissionAlert = true
                        }
                    } else {
                        self.permissionAlertMessage = "需要麦克风和语音识别权限来启动语音监听"
                        self.showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    // 权限获取成功，可以开始录音
                    print("麦克风权限已获取")
                } else {
                    self.permissionAlertMessage = "麦克风权限被拒绝，无法进行录音"
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

// RecordingsListView has been moved to WorkingVoiceRecordView.swift

struct VoiceRecordView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecordView()
    }
} 
