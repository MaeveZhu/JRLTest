import SwiftUI
import AVFoundation
import Speech
import CoreLocation

struct DrivingRecordsView: View {
    @State private var testSessions: [TestSession] = []
    @StateObject private var audioManager = UnifiedAudioManager()
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
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
                    headerSection
                    
                    if testSessions.isEmpty {
                        emptyStateView
                    } else {
                        sessionsList
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadTestSessions()
                startAnimations()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TestSessionEnded"))) { _ in
                loadTestSessions()
            }
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.02), lineWidth: 1)
                .frame(width: 500, height: 500)
                .offset(x: -200, y: -150)
                .rotationEffect(.degrees(animationPhase * 0.1))
                .animation(.linear(duration: 100).repeatForever(autoreverses: false), value: animationPhase)
            
            Rectangle()
                .fill(Color.black.opacity(0.005))
                .frame(width: 250, height: 3)
                .rotationEffect(.degrees(-15))
                .offset(x: 200, y: 300)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 25) {
            VStack(spacing: 15) {
                Text("Voice Recordings")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 1)
                
                Text("Historical voice recording data")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseScale)
                    
                    Image(systemName: "mic")
                        .font(.system(size: 30, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 12) {
                    Text("No Voice Recordings")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.black)
                    
                    Text("Completed voice recordings will appear here")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(testSessions, id: \.id) { session in
                    SessionCardView(
                        session: session,
                        audioManager: audioManager
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    private func startAnimations() {
        withAnimation {
            pulseScale = 1.2
        }
        
        withAnimation(.linear(duration: 100).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
// ... existing code ...

private func loadTestSessions() {
    let sessions = audioManager.getTestSessions()
    print("�� DrivingRecordsView: Loaded \(sessions.count) test sessions")
    
    for (index, session) in sessions.enumerated() {
        print("📱 Session \(index): \(session.recordingSegments.count) recording segments")
        for (segIndex, segment) in session.recordingSegments.enumerated() {
            print("📱   Segment \(segIndex): \(segment.fileName), speech: '\(segment.recognizedSpeech)'")
        }
    }
    
    testSessions = sessions.sorted { $0.startTime > $1.startTime }
}

// ... existing code ...
}

struct SessionCardView: View {
    let session: TestSession
    let audioManager: UnifiedAudioManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Session header with timestamp
            sessionHeader
            
            // Recording segments
            if !session.recordingSegments.isEmpty {
                recordingSegmentsSection
            } else {
                noRecordingsSection
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var sessionHeader: some View {
        VStack(spacing: 15) {
            HStack {
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(session.startTime))
                        .font(.system(size: 14, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Text("Started")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
            }
            
            // Session summary
            HStack(spacing: 30) {
                summaryItem(
                    icon: "waveform",
                    title: "Recordings",
                    value: "\(session.recordingSegments.count)"
                )
                
                summaryItem(
                    icon: "clock",
                    title: "Duration",
                    value: formatDuration(calculateTotalDuration())
                )
                
                summaryItem(
                    icon: "location",
                    title: "Location",
                    value: session.startCoordinate != nil ? "Recorded" : "None"
                )
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.02))
    }
    
    private func summaryItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 10, weight: .ultraLight))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.black)
        }
    }
    
    private var recordingSegmentsSection: some View {
        VStack(spacing: 1) {
            ForEach(Array(session.recordingSegments.enumerated()), id: \.offset) { index, segment in
                recordingSegmentRow(index: index + 1, segment: segment)
            }
        }
    }
    
    private func recordingSegmentRow(index: Int, segment: RecordingSegment) -> some View {
        VStack(spacing: 15) {
            // Segment header
            HStack {
                Text("Recording \(index)")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(formatDuration(segment.duration))
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // Speech recognition
            if !segment.recognizedSpeech.isEmpty && segment.recognizedSpeech != "Nothing is detected" {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Recognized Speech:")
                            .font(.system(size: 12, weight: .ultraLight))
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    Text(segment.recognizedSpeech)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            // Location coordinates
            coordinatesSection(segment: segment)
            
            // Audio playback
            audioPlaybackSection(segment: segment)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func coordinatesSection(segment: RecordingSegment) -> some View {
        HStack(spacing: 20) {
            coordinateInfo(label: "Start", coordinate: segment.startCoordinate)
            coordinateInfo(label: "End", coordinate: segment.endCoordinate)
        }
    }
    
    private func coordinateInfo(label: String, coordinate: CLLocationCoordinate2D?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .ultraLight))
                .foregroundColor(.gray)
            
            if let coord = coordinate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lat: \(String(format: "%.6f", coord.latitude))")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Text("Lon: \(String(format: "%.6f", coord.longitude))")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                }
            } else {
                Text("N/A")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func audioPlaybackSection(segment: RecordingSegment) -> some View {
        HStack(spacing: 15) {
            if FileManager.default.fileExists(atPath: segment.fileURL.path) {
                Button(action: {
                    audioManager.playAudioFile(at: segment.fileURL)
                }) {
                    Image(systemName: audioManager.isPlaying(segment.fileURL) ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio File:")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(.gray)
                    
                    Text(segment.fileName)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    // Show timestamp from filename
                    if segment.fileName.hasPrefix("recording_") {
                        let timestampString = String(segment.fileName.dropFirst("recording_".count).dropLast(4))
                        Text("📅 \(timestampString)")
                            .font(.system(size: 10, weight: .ultraLight))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            } else {
                Text("Audio file not available")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.gray)
                    .italic()
                
                Spacer()
            }
        }
    }
    
    private var noRecordingsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text("No recording segments")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.02))
        }
    }
    
    private func calculateTotalDuration() -> TimeInterval {
        return session.recordingSegments.reduce(0) { total, segment in
            total + segment.duration
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    DrivingRecordsView()
}
