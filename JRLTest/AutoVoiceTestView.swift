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
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Centered circular buttons
                    VStack(spacing: 40) {
                        // Start Listening Button
                        Button(action: {
                            startListening()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(audioManager.isListening ? Color.gray : Color.black)
                                    .frame(width: 120, height: 120)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "ear")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.white)
                                    
                                    Text("开始监听")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(audioManager.isRecording)
                        
                        // End Test Button
                        Button(action: {
                            endTest()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.black)
                                    
                                    Text("结束测试")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    
                    Spacer()
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

 
