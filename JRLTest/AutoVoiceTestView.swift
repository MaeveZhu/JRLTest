import SwiftUI
import CoreLocation

struct AutoVoiceTestView: View {
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    @Binding var showingResultsView: Bool
    
    @StateObject private var voiceManager = VoiceRecordingManager.shared
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
                
                VStack(spacing: 50) {
                    headerSection
                    
                    Spacer()
                    
                    statusIndicatorSection
                    
                    Spacer()
                    
                    instructionsSection
                    
                    if !voiceManager.recordingSegments.isEmpty {
                        recordingSegmentsSection
                    }
                    
                    Spacer()
                    
                    endTestButton
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 40)
            }
            .navigationTitle("Voice Control Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            startAutoVoiceTest()
            startAnimations()
        }
        .onDisappear {
            voiceManager.stopListening()
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
            Circle()
                .stroke(Color.gray.opacity(0.02), lineWidth: 1)
                .frame(width: 400, height: 400)
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
        VStack(spacing: 25) {
            VStack(spacing: 15) {
                Text("Voice Control Session")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 1)
            }
            
            VStack(spacing: 12) {
                sessionInfoRow(label: "Vehicle ID", value: vin)
                sessionInfoRow(label: "Test Type", value: tag)
                sessionInfoRow(label: "Session ID", value: testExecutionId)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 25)
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
        VStack(spacing: 40) {
            // Listening status
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Circle()
                        .fill(voiceManager.isListening ? Color.black.opacity(0.6) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(voiceManager.isListening ? pulseScale : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                    
                    Text(voiceManager.isListening ? "Voice Control Active" : "Voice Control Paused")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.black)
                }
                
                Text(voiceManager.isListening ? "System is monitoring for voice commands" : "Voice monitoring is currently paused")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Recording status
            if voiceManager.isRecording {
                VStack(spacing: 25) {
                    // Recording indicator
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 20, height: 20)
                            .scaleEffect(recordingPulse)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingPulse)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Recording Segment \(voiceManager.recordingSegments.count + 1)")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black)
                        
                        Text("Maintain 3 seconds of silence to automatically stop")
                            .font(.system(size: 12, weight: .ultraLight))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Voice Commands")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 15) {
                commandRow(command: "开始录音", description: "Begin recording audio segment")
                commandRow(command: "停止录音", description: "End current recording")
                commandRow(command: "结束测试", description: "Complete the test session")
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 25)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func commandRow(command: String, description: String) -> some View {
        HStack(spacing: 15) {
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
        VStack(alignment: .leading, spacing: 20) {
            Text("Recorded Segments")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(Array(voiceManager.recordingSegments.enumerated()), id: \.offset) { index, segment in
                    segmentRow(index: index + 1, segment: segment)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 25)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func segmentRow(index: Int, segment: RecordingSegment) -> some View {
        HStack(spacing: 15) {
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
        .padding(.vertical, 8)
    }
    
    private var endTestButton: some View {
        Button(action: {
            endTest()
        }) {
            HStack(spacing: 15) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 18)
                
                Text("Complete Test Session")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
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
        voiceManager.startTestSession(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: tag,
            startCoordinate: startCoordinate
        )
        voiceManager.startListening()
    }
    
    private func endTest() {
        voiceManager.stopListening()
        
        // Get the current location as end coordinate
        let endCoordinate = locationManager.currentLocation
        
        // End the test session with the end coordinate
        let _ = voiceManager.endTestSession(endCoordinate: endCoordinate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingResultsView = true
            dismiss()
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