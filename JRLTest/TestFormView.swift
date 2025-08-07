import SwiftUI
import AVFoundation
import CoreLocation
import Speech

struct TestFormView: View {
    @State private var vin = ""
    @State private var testExecutionId = ""
    @State private var selectedTag = "Engine Test"
    @State private var milesBefore = 138
    @State private var milesAfter = 160
    @State private var showingRecordingView = false
    @State private var showingResultsView = false
    @State private var showingLocationPermissionAlert = false
    @State private var showingMicrophonePermissionAlert = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    @StateObject private var locationManager = LocationManager()
    
    let availableTags = [
        "Engine Test",
        "Brake Test", 
        "Steering Test",
        "Suspension Test",
        "Electrical Test",
        "Climate Control Test"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.02)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Abstract background elements
                abstractBackgroundElements
                
                ScrollView {
                    VStack(spacing: 40) {
                        headerSection
                        formContainer
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(isPresented: $showingRecordingView) {
            recordingView
        }
        .alert("位置权限", isPresented: $showingLocationPermissionAlert) {
            locationPermissionButtons
        } message: {
            locationPermissionMessage
        }
        .alert("麦克风权限", isPresented: $showingMicrophonePermissionAlert) {
            microphonePermissionButtons
        } message: {
            microphonePermissionMessage
        }
        .alert("权限提示", isPresented: $showingPermissionAlert) {
            permissionButtons
        } message: {
            permissionMessage
        }
        .onAppear {
            locationManager.requestLocationPermission()
            startAnimations()
        }
    }
    
    // MARK: - View Components
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
            Circle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -150)
                .rotationEffect(.degrees(animationPhase * 0.3))
                .animation(.linear(duration: 40).repeatForever(autoreverses: false), value: animationPhase)
            
            Rectangle()
                .fill(Color.black.opacity(0.01))
                .frame(width: 200, height: 2)
                .rotationEffect(.degrees(45))
                .offset(x: 150, y: 200)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 25) {
            VStack(spacing: 8) {
                Text("Test Configuration")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 1)
                
                Text("Configure your vehicle test parameters")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var formContainer: some View {
        VStack(spacing: 35) {
            vinInputSection
            testExecutionIdSection
            tagSelectionSection
            milesBeforeSection
            startButtonSection
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var vinInputSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vehicle Identification")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(vin.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter VIN", text: $vin)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var testExecutionIdSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Execution Identifier")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(testExecutionId.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter Test Execution ID", text: $testExecutionId)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Test Category")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            tagPicker
        }
    }
    
    private var tagPicker: some View {
        Menu {
            ForEach(availableTags, id: \.self) { tag in
                Button(tag) {
                    selectedTag = tag
                }
            }
        } label: {
            HStack {
                Text(selectedTag)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .frame(height: 50)
            .background(Color.gray.opacity(0.02))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var milesBeforeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Initial Mileage")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            HStack(spacing: 20) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.02))
                        .frame(height: 50)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    TextField("Miles", value: $milesBefore, format: .number)
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 8) {
                    Button(action: { milesBefore += 1 }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .ultraLight))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 20)
                            .background(Color.gray.opacity(0.05))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Button(action: { 
                        if milesBefore > 0 { milesBefore -= 1 }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .ultraLight))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 20)
                            .background(Color.gray.opacity(0.05))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    private var startButtonSection: some View {
        VStack(spacing: 20) {
            Button(action: {
                checkPermissionsAndStart()
            }) {
                HStack(spacing: 15) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 20)
                        .scaleEffect(y: pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    
                    Text("Initialize Test Session")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                        
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    Rectangle()
                        .fill(vin.isEmpty || testExecutionId.isEmpty ? Color.gray.opacity(0.3) : Color.black)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
            .disabled(vin.isEmpty || testExecutionId.isEmpty)
            .buttonStyle(PlainButtonStyle())
            
            Text("Ensure all fields are completed before initialization")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // 在TestFormView中更新recordingView:

    private var recordingView: some View {
        AutoVoiceTestView(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: selectedTag,
            startCoordinate: startCoordinate,
            showingResultsView: $showingResultsView
        )
    }
    
    
    private var locationPermissionButtons: some View {
        Group {
            Button("允许") {
                locationManager.requestLocationPermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var locationPermissionMessage: some View {
        Text("需要位置权限来记录测试时的GPS坐标")
    }
    
    private var microphonePermissionButtons: some View {
        Group {
            Button("允许") {
                requestMicrophonePermission()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var microphonePermissionMessage: some View {
        Text("需要麦克风权限来进行语音录音和语音识别")
    }
    
    private var permissionButtons: some View {
        Button("确定") { }
    }
    
    private var permissionMessage: some View {
        Text(permissionAlertMessage)
    }
    
    // MARK: - Methods
    
    private func startAnimations() {
        withAnimation {
            pulseScale = 1.2
        }
        
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    private func checkPermissionsAndStart() {
        // 记录起始GPS坐标
        startCoordinate = locationManager.currentLocation
        
        // 检查位置权限
        if locationManager.locationStatus != .available {
            showingLocationPermissionAlert = true
            return
        }
        
        // 检查麦克风权限
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        if microphoneStatus != .granted {
            showingMicrophonePermissionAlert = true
            return
        }
        
        // 检查语音识别权限
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus != .authorized {
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.startVoiceControlledTest()
                    } else {
                        self.permissionAlertMessage = "语音识别权限被拒绝，无法进行语音控制测试"
                        self.showingPermissionAlert = true
                    }
                }
            }
        } else {
            startVoiceControlledTest()
        }
    }

    private func startVoiceControlledTest() {
        // Start voice-controlled test session
        UnifiedAudioManager.shared.startTestSession(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: selectedTag,
            startCoordinate: startCoordinate
        )
        
        // Navigate to voice recording view
        showingRecordingView = true
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    // 权限获取成功，可以开始
                    self.showingRecordingView = true
                } else {
                    self.permissionAlertMessage = "麦克风权限被拒绝，无法进行录音"
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

struct TestFormView_Previews: PreviewProvider {
    static var previews: some View {
        TestFormView()
    }
} 
