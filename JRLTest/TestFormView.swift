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
    @EnvironmentObject var carPlayManager: CarPlayManager
    
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
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white, 
                        Color.gray.opacity(0.02),
                        Color.blue.opacity(0.01)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                abstractBackgroundElements
                
                ScrollView {
                    VStack(spacing: carPlayManager.isCarPlayConnected ? 30 : 40) {
                        headerSection
                        formContainer
                        
                        // CarPlay quick start section
                        if carPlayManager.isCarPlayConnected {
                            carPlayQuickStartSection
                        }
                    }
                    .padding(.horizontal, carPlayManager.isCarPlayConnected ? 25 : 30)
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
    
    private var carPlayQuickStartSection: some View {
        VStack(spacing: 20) {
            Text("CarPlay 快速开始")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
            
            HStack(spacing: 20) {
                quickStartButton(
                    action: {
                        startQuickTest()
                    },
                    icon: "play.circle.fill",
                    title: "快速测试",
                    color: .green
                )
                
                quickStartButton(
                    action: {
                        startRecordingOnly()
                    },
                    icon: "record.circle.fill",
                    title: "仅录音",
                    color: .red
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(15)
    }
    
    private func quickStartButton(
        action: @escaping () -> Void,
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(width: 100, height: 100)
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startQuickTest() {
        // Auto-fill form with default values for quick testing
        sectionA = "CARPLAY_TEST"
        sectionB = UUID().uuidString
        sectionC = UUID().uuidString
        sectionD = "CarPlay Quick Test"
        selectedSectionE = "Option 1"
        sectionF = 1
        
        // Start test immediately
        startTest()
    }
    
    private func startRecordingOnly() {
        // Start recording without form data
        UnifiedAudioManager.shared.startSiriDrivingTest()
        showingRecordingView = true
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
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
        VStack(spacing: carPlayManager.isCarPlayConnected ? 20 : 25) {
            VStack(spacing: 8) {
                Text("测试表单")
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 32 : 28, weight: .light))
                    .foregroundColor(.black)
                
                Text("填写测试信息")
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            
            Rectangle()
                .fill(Color.black)
                .frame(width: 80, height: 1)
                .scaleEffect(x: pulseScale, anchor: .center)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var formContainer: some View {
        VStack(spacing: carPlayManager.isCarPlayConnected ? 25 : 30) {
            formField(
                title: "Section A",
                placeholder: "输入 Section A",
                text: $sectionA
            )
            
            formField(
                title: "Section B", 
                placeholder: "输入 Section B",
                text: $sectionB
            )
            
            formField(
                title: "Section C",
                placeholder: "输入 Section C", 
                text: $sectionC
            )
            
            formField(
                title: "Section D",
                placeholder: "输入 Section D",
                text: $sectionD
            )
            
            // CarPlay-optimized picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Section E")
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16, weight: .medium))
                    .foregroundColor(.black)
                
                Menu {
                    ForEach(availableSectionEOptions, id: \.self) { option in
                        Button(option) {
                            selectedSectionE = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSectionE)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, carPlayManager.isCarPlayConnected ? 20 : 15)
                    .padding(.vertical, carPlayManager.isCarPlayConnected ? 18 : 15)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // CarPlay-optimized number input
            VStack(alignment: .leading, spacing: 8) {
                Text("Section F")
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16, weight: .medium))
                    .foregroundColor(.black)
                
                HStack {
                    Button("-") {
                        if sectionF > 1 {
                            sectionF -= 1
                        }
                    }
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 24 : 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: carPlayManager.isCarPlayConnected ? 50 : 40, height: carPlayManager.isCarPlayConnected ? 50 : 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text("\(sectionF)")
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 24 : 20, weight: .medium))
                        .frame(minWidth: 60)
                        .padding(.horizontal, 20)
                    
                    Button("+") {
                        sectionF += 1
                    }
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 24 : 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: carPlayManager.isCarPlayConnected ? 50 : 40, height: carPlayManager.isCarPlayConnected ? 50 : 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // CarPlay-optimized start button
            Button(action: startTest) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 24 : 20))
                    Text("开始测试")
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 20 : 18, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: carPlayManager.isCarPlayConnected ? 60 : 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(sectionA.isEmpty || sectionB.isEmpty || sectionC.isEmpty || sectionD.isEmpty)
            .opacity(sectionA.isEmpty || sectionB.isEmpty || sectionC.isEmpty || sectionD.isEmpty ? 0.5 : 1.0)
        }
    }
    
    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16, weight: .medium))
                .foregroundColor(.black)
            
            TextField(placeholder, text: text)
                .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16))
                .padding(.horizontal, carPlayManager.isCarPlayConnected ? 20 : 15)
                .padding(.vertical, carPlayManager.isCarPlayConnected ? 18 : 15)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private func startTest() {
        guard !sectionA.isEmpty && !sectionB.isEmpty && !sectionC.isEmpty && !sectionD.isEmpty else {
            return
        }
        
        // Check permissions first
        if !UnifiedAudioManager.shared.checkPermissions() {
            permissionAlertMessage = UnifiedAudioManager.shared.getPermissionStatus()
            showingPermissionAlert = true
            return
        }
        
        // Get current location
        startCoordinate = locationManager.currentLocation
        
        // Start test session
        UnifiedAudioManager.shared.startTestSession(
            operatorCDSID: sectionA,
            driverCDSID: sectionB,
            testExecution: sectionC,
            testProcedure: sectionD,
            testType: selectedSectionE,
            testNumber: sectionF,
            startCoordinate: startCoordinate
        )
        
        // Start recording
        UnifiedAudioManager.shared.startRecordingWithCoordinate()
        
        // Show recording view
        showingRecordingView = true
    }
    
    private var recordingView: some View {
        AutoVoiceTestView(
            operatorCDSID: sectionA,
            driverCDSID: sectionB,
            testExecution: sectionC,
            testProcedure: sectionD,
            testType: selectedSectionE,
            testNumber: sectionF,
            startCoordinate: startCoordinate,
            showingResultsView: $showingResultsView
        )
    }
    
    private var locationPermissionButtons: some View {
        Group {
            Button("设置") {
                UnifiedAudioManager.shared.openSettings()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var locationPermissionMessage: some View {
        Text("需要位置权限来记录测试位置信息")
    }
    
    private var microphonePermissionButtons: some View {
        Group {
            Button("设置") {
                UnifiedAudioManager.shared.openSettings()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var microphonePermissionMessage: some View {
        Text("需要麦克风权限来录制音频")
    }
    
    private var permissionButtons: some View {
        Group {
            Button("设置") {
                UnifiedAudioManager.shared.openSettings()
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    private var permissionMessage: some View {
        Text(permissionAlertMessage)
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

#Preview {
    TestFormView()
        .environmentObject(CarPlayManager.shared)
} 
