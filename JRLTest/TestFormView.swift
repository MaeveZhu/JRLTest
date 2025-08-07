import SwiftUI
import AVFoundation
import CoreLocation
import Speech

struct TestFormView: View {
    @State private var sectionA = ""
    @State private var sectionB = ""
    @State private var sectionC = ""
    @State private var sectionD = ""
    @State private var selectedSectionE = "Test Type"
    @State private var sectionF = 1
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
    
    let availableSectionEOptions = [
        "Option 1",
        "Option 2", 
        "Option 3",
        "Option 4",
        "Option 5"
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
                Text("XRAY Test Configuration")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 1)
                
                Text("Configure your XRAY test parameters")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var formContainer: some View {
        VStack(spacing: 35) {
            sectionAInput
            sectionBInput
            sectionCInput
            sectionDInput
            sectionESelection
            sectionFInput
            nextButtonSection
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var sectionAInput: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Operator CDSID")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(sectionA.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter Operator CDSID", text: $sectionA)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var sectionBInput: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Driver CDSID")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(sectionB.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter Driver CDSID", text: $sectionB)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var sectionCInput: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Test Execution")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(sectionC.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter Test Execution", text: $sectionC)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var sectionESelection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Section E")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            sectionEPicker
        }
    }
    
    private var sectionEPicker: some View {
        Menu {
            ForEach(availableSectionEOptions, id: \.self) { option in
                Button(option) {
                    selectedSectionE = option
                }
            }
        } label: {
            HStack {
                Text(selectedSectionE)
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
    
    private var sectionDInput: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Test Procedure")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
                
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(sectionD.isEmpty ? Color.gray.opacity(0.2) : Color.black.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("Enter Test Procedure", text: $sectionD)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var sectionFInput: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Section F")
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
                    
                    TextField("Value", value: $sectionF, format: .number)
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 8) {
                    Button(action: { sectionF += 1 }) {
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
                        if sectionF > 0 { sectionF -= 1 }
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
    
    private var nextButtonSection: some View {
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
                    
                    Text("Next")
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
                        .fill(isFormComplete ? Color.black : Color.gray.opacity(0.3))
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
            .disabled(!isFormComplete)
            .buttonStyle(PlainButtonStyle())
            
            Text("Ensure all fields are completed before proceeding")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // Computed property to check if form is complete
    private var isFormComplete: Bool {
        return !sectionA.isEmpty && 
               !sectionB.isEmpty && 
               !sectionC.isEmpty && 
               !sectionD.isEmpty && 
               sectionF > 0
    }

    private var recordingView: some View {
        AutoVoiceTestView(
            vin: sectionA, // Using sectionA as VIN
            testExecutionId: sectionB, // Using sectionB as testExecutionId
            tag: selectedSectionE, // Using selectedSectionE as tag
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
            vin: sectionA,
            testExecutionId: sectionB,
            tag: selectedSectionE,
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
