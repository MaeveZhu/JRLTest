import SwiftUI
import CoreLocation

struct AutoVoiceTestView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    @Binding var showingResultsView: Bool
    
    @StateObject private var audioManager = UnifiedAudioManager()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var recordingPulse: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.01)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Abstract background elements
                abstractBackgroundElements
                
                VStack(spacing: 5) {
                    headerSection
                    
                    Spacer(minLength: 5)
                    
                    statusIndicatorSection
                    
                    Spacer(minLength: 5)
                    
                    instructionsSection
                    
                    if !audioManager.recordingSegments.isEmpty {
                        recordingSegmentsSection
                    }
                    
                    controlButtonsSection
                    
                    endTestButton
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
            }
        }
        .onAppear {
            startAutoVoiceTest()
            startAnimations()
            setupSiriNotifications()
        }
        .onDisappear {
            audioManager.stopListening()
            removeSiriNotifications()
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
            Circle()
                .stroke(Color.gray.opacity(0.02), lineWidth: 1)
                .frame(width: 400, height: 200)
                .offset(x: -150, y: -100)
                .rotationEffect(.degrees(animationPhase * 0.15))
                .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: animationPhase)
            
            Rectangle()
                .fill(Color.black.opacity(0.01))
                .frame(width: 200, height: 3)
                .rotationEffect(.degrees(25))
                .offset(x: 180, y: 200)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 7) {
            VStack(spacing: 10) {
                Text("语音控制测试")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 1)
            }
            
            VStack(spacing: 8) {
                sessionInfoRow(label: "Vehicle ID", value: vin)
                sessionInfoRow(label: "Test Type", value: tag)
                sessionInfoRow(label: "Session ID", value: testExecutionId)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func sessionInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundColor(.black)
        }
    }
    
    private var statusIndicatorSection: some View {
        VStack(spacing: 7) {
            // Listening status
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(audioManager.isListening ? Color.black.opacity(0.6) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(audioManager.isListening ? pulseScale : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    
                    Text(audioManager.isListening ? "Voice Control Active" : "Voice Control Paused")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.black)
                }
                
                Text(audioManager.isListening ? "System is monitoring for voice commands" : "Voice monitoring is currently paused")
                    .font(.system(size: 12, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Recording status
            if audioManager.isRecording {
                VStack(spacing: 12) {
                    // Recording indicator
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            .frame(width: 80, height: 60)
                        
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 16, height: 16)
                            .scaleEffect(recordingPulse)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingPulse)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Recording Segment \(audioManager.recordingSegments.count + 1)")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.black)
                        
                        Text("5秒静音或3分钟超时自动停止")
                            .font(.system(size: 10, weight: .ultraLight))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Siri Voice Commands")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 8) {
                commandRow(command: "Hey Siri, start driving test audio in JRLTest", description: "开始录音并捕获位置信息 (最多3分钟)")
                commandRow(command: "5秒静音或3分钟超时", description: "自动停止录音并返回监听模式")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func commandRow(command: String, description: String) -> some View {
        HStack(spacing: 7) {
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 3, height: 25)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(command)
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private var recordingSegmentsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Recorded Segments")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 6) {
                ForEach(Array(audioManager.recordingSegments.enumerated()), id: \.offset) { index, segment in
                    segmentRow(index: index + 1, segment: segment)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func segmentRow(index: Int, segment: RecordingSegment) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 6, height: 6)
            
            Text("Segment \(index)")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(formatDuration(segment.duration))
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private var controlButtonsSection: some View {
        VStack(spacing: 0) {
            // Start Listening Button
            Button(action: {
                startListening()
            }) {
                HStack(spacing: 7) {
                    Image(systemName: "ear")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white)
                    
                    Text("开始监听")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(audioManager.isListening ? Color.gray : Color.blue)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(audioManager.isRecording)
            
            // Status indicator
            if audioManager.isListening {
                Text("正在监听语音命令...")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.green)
                    .padding(.top, 5)
            }
        }
    }
    
    private var endTestButton: some View {
        Button(action: {
            endTest()
        }) {
            HStack(spacing: 3) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 10)
                
                Text("结束测试")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.white)
            }
                            .padding(.horizontal, 25)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startAnimations() {
        withAnimation {
            pulseScale = 1.3
            recordingPulse = 1.5
        }
        
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startAutoVoiceTest() {
        // Start the test session with initial parameters
        audioManager.startTestSession(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: tag,
            startCoordinate: startCoordinate
        )
        // Don't start listening automatically - user must click button
    }
    
    private func startListening() {
        audioManager.startListening()
        print("🎤 AutoVoiceTestView: Started listening for voice commands")
    }
    
    private func endTest() {
        audioManager.stopListening()
        
        // Get the current location as end coordinate
        let endCoordinate = locationManager.currentLocation
        
        // End the test session with the end coordinate
        let _ = audioManager.endTestSession(endCoordinate: endCoordinate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingResultsView = true
            dismiss()
        }
    }
    
    // MARK: - SiriKit Integration
    
    private func setupSiriNotifications() {
        print("🔔 AutoVoiceTestView: Setting up Siri notification observers")
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriDrivingTestStarted"),
            object: nil,
            queue: .main
        ) { [self] notification in
            print("🔔 AutoVoiceTestView: SiriDrivingTestStarted notification received")
            self.handleSiriDrivingTestStarted(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriStartRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            print("🔔 AutoVoiceTestView: SiriStartRecording notification received")
            self.handleSiriStartRecording()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriStopRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            print("🔔 AutoVoiceTestView: SiriStopRecording notification received")
            self.handleSiriStopRecording()
        }
        
        print("✅ AutoVoiceTestView: All Siri notification observers registered")
    }
    
    private func removeSiriNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("SiriDrivingTestStarted"),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("SiriStartRecording"),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("SiriStopRecording"),
            object: nil
        )
    }
    
    private func handleSiriDrivingTestStarted(_ notification: Notification) {
        guard let testSession = notification.object as? TestSession else { return }
        
        // Update the current test session
        audioManager.currentTestSession = testSession
        
        // Start recording automatically
        audioManager.startListening()
        
        // Update UI to show recording is active
        DispatchQueue.main.async {
            // Trigger UI updates
            self.audioManager.isRecording = true
        }
        
        print("✅ SiriKit: Driving test started via voice command")
    }
    
    private func handleSiriStartRecording() {
        print("🎤 AutoVoiceTestView: SiriStartRecording notification received!")
        print("🎤 AutoVoiceTestView: Current recording state - isRecording: \(audioManager.isRecording)")
        
        // Start recording with coordinate if not already recording
        if !audioManager.isRecording {
            print("🎤 AutoVoiceTestView: Calling audioManager.startRecordingWithCoordinate()")
            audioManager.startRecordingWithCoordinate()
            print("✅ AutoVoiceTestView: Recording started via voice command")
        } else {
            print("ℹ️ AutoVoiceTestView: Recording is already active")
        }
    }
    
    private func handleSiriStopRecording() {
        print("🛑 AutoVoiceTestView: SiriStopRecording notification received!")
        print("🛑 AutoVoiceTestView: Current recording state - isRecording: \(audioManager.isRecording)")
        
        // Stop recording if currently recording
        if audioManager.isRecording {
            print("🛑 AutoVoiceTestView: Calling audioManager.stopRecording()")
            audioManager.stopRecording()
            print("✅ AutoVoiceTestView: Recording stopped via voice command")
        } else {
            print("ℹ️ AutoVoiceTestView: No active recording to stop")
        }
    }
}

#Preview {
    AutoVoiceTestView(
        vin: "TEST123",
        testExecutionId: "EXEC001",
        tag: "Engine Test",
        startCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        showingResultsView: .constant(false)
    )
} 
