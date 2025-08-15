import SwiftUI
import CoreLocation

struct AutoVoiceTestView: View {
    let vin: String
    let startCoordinate: CLLocationCoordinate2D?
    @Binding var showingResultsView: Bool
    
    @StateObject private var carTestManager = CarTestManager.shared
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
                        // Voice Command Instructions
                        VStack(spacing: 15) {
                            Text("Voice Commands")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 8) {
                                Text("Say: \"开始汽车测试录音\"")
                                    .font(.system(size: 12, weight: .ultraLight))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("Say: \"停止汽车测试录音\"")
                                    .font(.system(size: 12, weight: .ultraLight))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("Recording will auto-stop after 3 minutes")
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
                            startRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(carTestManager.isRecording ? Color.red : Color.black)
                                    .frame(width: 120, height: 120)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: carTestManager.isRecording ? "stop.fill" : "record.circle")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.white)
                                    
                                    Text(carTestManager.isRecording ? "停止录音" : "开始录音")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Recording duration display
                        if carTestManager.isRecording {
                            VStack(spacing: 8) {
                                Text("Recording: \(formatDuration(carTestManager.recordingDuration))")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(.red)
                                
                                if !carTestManager.recognizedSpeech.isEmpty {
                                    Text("Speech: \(carTestManager.recognizedSpeech)")
                                        .font(.system(size: 12, weight: .ultraLight))
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
            removeSiriNotifications()
        }
    }
    
    var abstractBackgroundElements: some View {
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
    
    func startAnimations() {
        withAnimation {
            pulseScale = 1.3
            recordingPulse = 1.5
        }
        
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startAutoVoiceTest() {
        carTestManager.setLocationManager(locationManager)
        
        carTestManager.startTestSession(
            startCoordinate: startCoordinate
        )
    }
    
    func startRecording() {
        if carTestManager.isRecording {
            carTestManager.stopRecording()
        } else {
            carTestManager.startRecording()
        }
    }
    
    func endTest() {
        carTestManager.endTestSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    func setupSiriNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StartRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if !carTestManager.isRecording {
                carTestManager.startRecording()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StopRecording"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if carTestManager.isRecording {
                carTestManager.stopRecording()
            }
        }
    }
    
    func removeSiriNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("StartRecording"),
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("StopRecording"),
            object: nil
        )
    }
}
