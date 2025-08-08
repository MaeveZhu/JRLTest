import SwiftUI
import AVFoundation
import Speech
import CoreLocation

struct DrivingRecordsView: View {
    @State private var testSessions: [TestSession] = []
    @State private var expandedVINs: Set<String> = []
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
                Text("Session Records")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.black)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 1)
                
                Text("Historical test session data")
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
                    
                    Image(systemName: "folder")
                        .font(.system(size: 30, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 12) {
                    Text("No Session Records")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.black)
                    
                    Text("Completed voice control tests will appear here")
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
                ForEach(groupedSessions.keys.sorted(), id: \.self) { vin in
                    VINSectionView(
                        vin: vin,
                        sessions: groupedSessions[vin] ?? [],
                        isExpanded: expandedVINs.contains(vin),
                        audioManager: audioManager,
                        onToggle: {
                            toggleVIN(vin)
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    private var groupedSessions: [String: [TestSession]] {
        Dictionary(grouping: testSessions, by: { $0.vin })
    }
    
    private func toggleVIN(_ vin: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedVINs.contains(vin) {
                expandedVINs.remove(vin)
            } else {
                expandedVINs.insert(vin)
            }
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
    
    private func loadTestSessions() {
        let sessions = audioManager.getTestSessions()
        testSessions = sessions.sorted { $0.startTime > $1.startTime }
    }
    
    // Helper function to calculate total duration
    private func calculateTotalDuration(for session: TestSession) -> TimeInterval {
        return session.recordingSegments.reduce(0) { total, segment in
            total + segment.duration
        }
    }
}

struct VINSectionView: View {
    let vin: String
    let sessions: [TestSession]
    let isExpanded: Bool
    let audioManager: UnifiedAudioManager
    let onToggle: () -> Void
    @State private var hoverState = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // VIN Header
            vinHeaderButton
            
            // Expanded Content
            if isExpanded {
                expandedContent
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var vinHeaderButton: some View {
        Button(action: onToggle) {
            HStack(spacing: 20) {
                chevronIcon
                vinInfo
                Spacer()
                latestSessionDate
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 30)
            .background(headerBackground)
            .overlay(headerBorder)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var chevronIcon: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 12, weight: .ultraLight))
            .foregroundColor(.gray)
            .frame(width: 20)
            .rotationEffect(.degrees(isExpanded ? 0 : -90))
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    private var vinInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VIN: \(vin)")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            Text("\(sessions.count) sessions • \(totalRecordings) recordings")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.gray)
        }
    }
    
    private var latestSessionDate: some View {
        Group {
            if let latestSession = sessions.first {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(latestSession.startTime))
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                    
                    Text("Latest")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var headerBackground: some View {
        Rectangle()
            .fill(isExpanded ? Color.gray.opacity(0.02) : Color.white)
    }
    
    private var headerBorder: some View {
        Rectangle()
            .stroke(Color.gray.opacity(isExpanded ? 0.15 : 0.1), lineWidth: 1)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 1) {
            ForEach(sessions, id: \.id) { session in
                SessionRowView(
                    session: session,
                    audioManager: audioManager,
                    onTap: { }
                )
            }
        }
        .padding(.top, 1)
    }
    
    private var totalRecordings: Int {
        sessions.reduce(0) { total, session in
            total + session.recordingSegments.count
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SessionRowView: View {
    let session: TestSession
    let audioManager: UnifiedAudioManager
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Session header
            sessionHeader
            
            // Audio clips
            if !session.recordingSegments.isEmpty {
                audioClipsSection
            } else {
                // No recording segments
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
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.gray.opacity(0.02))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.05), lineWidth: 1)
                    )
                }
            }
        }
        .background(Color.white)
        .overlay(sessionBorder)
    }
    
    private var sessionHeader: some View {
        HStack(spacing: 20) {
            sessionIndicator
            sessionInfo
            Spacer()
            sessionDetails
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
    }
    
    private var sessionIndicator: some View {
        Circle()
            .fill(Color.black.opacity(0.6))
            .frame(width: 6, height: 6)
    }
    
    private var sessionInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.tag)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Operator: \(session.vin)")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(.gray)
                
                Text("Driver: \(session.testExecutionId)")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(.gray)
                
                Text("Started: \(formatTime(session.startTime))")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var sessionDetails: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(session.recordingSegments.count) segments")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.black)
            
            Text(formatDuration(calculateSessionDuration()))
                .font(.system(size: 10, weight: .ultraLight, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
    
    private var audioClipsSection: some View {
        VStack(spacing: 1) {
            ForEach(Array(session.recordingSegments.enumerated()), id: \.offset) { index, segment in
                audioClipRow(index: index + 1, segment: segment)
            }
        }
    }
    
    private func audioClipRow(index: Int, segment: RecordingSegment) -> some View {
        VStack(spacing: 12) {
            // Audio clip header
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 8, height: 8)
                
                Text("Audio Clip \(index)")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(formatDuration(segment.duration))
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // Coordinates info
            coordinatesSection(segment: segment)
            
            // Speech recognition section - always show for debugging
            speechRecognitionSection(segment: segment)
            
            // Audio player
            audioPlayerSection(segment: segment)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .background(Color.gray.opacity(0.02))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func speechRecognitionSection(segment: RecordingSegment) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Recognized Speech:")
                    .font(.system(size: 11, weight: .ultraLight))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            if segment.recognizedSpeech.isEmpty || segment.recognizedSpeech == "Speech recognition not available in this mode" {
                Text("Nothing is detected")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
            } else {
                Text(segment.recognizedSpeech)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(6)
            }
        }
    }
    
    private func coordinatesSection(segment: RecordingSegment) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                coordinateInfo(label: "Start", coordinate: segment.startCoordinate)
                coordinateInfo(label: "End", coordinate: segment.endCoordinate)
            }
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
    
    private func audioPlayerSection(segment: RecordingSegment) -> some View {
        HStack(spacing: 15) {
            // Check if audio file exists
            if FileManager.default.fileExists(atPath: segment.fileURL.path) {
                // Play button
                Button(action: {
                    audioManager.playAudioFile(at: segment.fileURL)
                }) {
                    Image(systemName: audioManager.isPlaying(segment.fileURL) ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                
                // Audio file info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio File:")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(.gray)
                    
                    Text(segment.fileName)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text("✅ File exists")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.green)
                }
                
                Spacer()
            } else {
                // No recording available
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio Recording:")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(.gray)
                    
                    Text("No recording")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.gray)
                        .italic()
                }
                
                Spacer()
            }
        }
    }
    
    private var sessionBorder: some View {
        Rectangle()
            .stroke(Color.gray.opacity(0.05), lineWidth: 1)
    }
    
    private func calculateSessionDuration() -> TimeInterval {
        return session.recordingSegments.reduce(0) { total, segment in
            total + segment.duration
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
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
