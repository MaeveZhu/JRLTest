import SwiftUI
import AVFoundation

struct DrivingRecordsView: View {
    @State private var testSessions: [TestSession] = []
    @State private var expandedVINs: Set<String> = []
    @State private var showingSessionDetail = false
    @State private var selectedSession: TestSession?
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var voiceManager = VoiceRecordingManager.shared
    @State private var animationPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
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
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session, audioManager: audioManager)
                }
            }
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
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
                        },
                        onSessionTap: { session in
                            selectedSession = session
                            showingSessionDetail = true
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
        testSessions = voiceManager.getTestSessions().sorted { $0.startTime > $1.startTime }
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
    let audioManager: AudioManager
    let onToggle: () -> Void
    let onSessionTap: (TestSession) -> Void
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
                    onTap: { onSessionTap(session) }
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
    let audioManager: AudioManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                sessionIndicator
                sessionInfo
                Spacer()
                sessionDetails
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(sessionBorder)
        }
        .buttonStyle(PlainButtonStyle())
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
            
            Text("Started: \(formatTime(session.startTime))")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.gray)
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

struct SessionDetailView: View {
    let session: TestSession
    let audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                sessionHeader
                segmentsList
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sessionHeader: some View {
        VStack(spacing: 20) {
            Text(session.tag)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                detailRow(label: "VIN", value: session.vin)
                detailRow(label: "Duration", value: formatDuration(calculateTotalDuration()))
                detailRow(label: "Segments", value: "\(session.recordingSegments.count)")
            }
            .padding(25)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var segmentsList: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recording Segments")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.black)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(session.recordingSegments.enumerated()), id: \.offset) { index, segment in
                        segmentRow(index: index + 1, segment: segment)
                    }
                }
            }
        }
    }
    
    private func segmentRow(index: Int, segment: RecordingSegment) -> some View {
        HStack(spacing: 15) {
            Text("Segment \(index)")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("Play") {
                audioManager.startPlayback(url: segment.fileURL)
            }
            .font(.system(size: 12, weight: .light))
            .foregroundColor(.black)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            Text(formatDuration(segment.duration))
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .foregroundColor(.black)
        }
    }
    
    private func calculateTotalDuration() -> TimeInterval {
        return session.recordingSegments.reduce(0) { total, segment in
            total + segment.duration
        }
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
