import SwiftUI
import CoreLocation

struct AutoVoiceTestView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    @Binding var showingResultsView: Bool
    
    @StateObject private var audioManager = UnifiedAudioManager.shared
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var recordingPulse: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.01)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                abstractBackgroundElements
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 40) {
                        // Siri Command Instructions
                        VStack(spacing: 15) {
                            Text("Siri Commands")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 8) {
                                Text("Say: \"Hey Siri, Start Driving Test Audio\"")
                                    .font(.system(size: 12, weight: .ultraLight))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("Say: \"Hey Siri, Stop Driving Test Audio\"")
                                    .font(.system(size: 12, weight: .ultraLight))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("Recording will auto-stop after 3 minutes")
                                    .font(.system(size: 10, weight: .ultraLight))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                
                                Text("Or use the buttons below")
                                    .font(.system(size: 10, weight: .ultraLight))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            startListening()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(audioManager.isListening ? Color.gray : Color.black)
                                    .frame(width: 140, height: 140)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "ear")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.white)
                                    
                                    Text("Start Monitoring")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(audioManager.isRecording)
                        
                        // Speech recognition status
                        if audioManager.isRecognizingSpeech {
                            VStack(spacing: 8) {
                                Text("🎤 Speech Recognition Active")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.blue)
                                
                                if !audioManager.recognizedSpeech.isEmpty {
                                    Text(audioManager.recognizedSpeech)
                                        .font(.system(size: 10, weight: .ultraLight))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        Button(action: {
                            endTest()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.black)
                                    
                                    Text("End Session")
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
        audioManager.setLocationManager(locationManager)
        
        audioManager.requestPermissions { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ AutoVoiceTestView: All permissions granted")
                } else {
                    print("❌ AutoVoiceTestView: Some permissions still missing")
                }
            }
        }
        
        audioManager.startTestSession(
            operatorCDSID: vin,
            driverCDSID: testExecutionId,
            testExecution: testExecutionId,
            testProcedure: "Auto Voice Test",
            testType: tag,
            testNumber: 1,
            startCoordinate: startCoordinate
        )
    }
    
    private func startListening() {
        audioManager.startListening()
    }
    
    private func endTest() {
        audioManager.stopListening()
        
        audioManager.endTestSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func setupSiriNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriDrivingTestStarted"),
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let testSession = notification.object as? TestSession else { return }
            
            audioManager.currentTestSession = testSession
            audioManager.startListening()
            
            DispatchQueue.main.async {
                self.audioManager.isRecording = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriStartRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if !audioManager.isRecording {
                audioManager.startRecordingWithCoordinate()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SiriStopRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if audioManager.isRecording {
                audioManager.stopRecording()
            }
        }
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
}


