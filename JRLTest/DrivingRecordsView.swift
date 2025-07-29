import SwiftUI
import AVFoundation

struct DrivingRecordsView: View {
    @State private var testSessions: [TestSession] = []
    @State private var expandedVINs: Set<String> = []
    @State private var showingSessionDetail = false
    @State private var selectedSession: TestSession?
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var voiceManager = VoiceRecordingManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if testSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("行车记录")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadTestSessions()
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session, audioManager: audioManager)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无测试记录")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("完成语音控制测试后记录将显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sessionsList: some View {
        List {
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
        .listStyle(PlainListStyle())
    }
    
    private var groupedSessions: [String: [TestSession]] {
        Dictionary(grouping: testSessions, by: { $0.vin })
    }
    
    private func toggleVIN(_ vin: String) {
        if expandedVINs.contains(vin) {
            expandedVINs.remove(vin)
        } else {
            expandedVINs.insert(vin)
        }
    }
    
    private func loadTestSessions() {
        testSessions = voiceManager.getTestSessions().sorted { $0.startTime > $1.startTime }
    }
}

struct VINSectionView: View {
    let vin: String
    let sessions: [TestSession]
    let isExpanded: Bool
    let audioManager: AudioManager
    let onToggle: () -> Void
    let onSessionTap: (TestSession) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // VIN Header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VIN: \(vin)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(sessions.count) 次测试 • \(totalRecordings) 段录音")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Latest test date
                    if let latestSession = sessions.first {
                        Text(formatDate(latestSession.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(sessions, id: \.id) { session in
                        SessionRowView(
                            session: session,
                            audioManager: audioManager,
                            onTap: { onSessionTap(session) }
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var totalRecordings: Int {
        sessions.reduce(0) { $0 + $1.recordingSegments.count }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(session.tag)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(session.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("测试ID: \(session.testExecutionId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(session.recordingSegments.count) 段录音")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                // Recording segments preview
                if !session.recordingSegments.isEmpty {
                    HStack {
                        ForEach(session.recordingSegments.prefix(3), id: \.id) { segment in
                            RecordingSegmentButton(segment: segment, audioManager: audioManager)
                        }
                        
                        if session.recordingSegments.count > 3 {
                            Text("+\(session.recordingSegments.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RecordingSegmentButton: View {
    let segment: RecordingSegment
    let audioManager: AudioManager
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            if isPlaying {
                audioManager.stopPlayback()
            } else {
                _ = audioManager.startPlayback(url: segment.fileURL)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("\(segment.segmentNumber)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(audioManager.$isPlaying) { playing in
            isPlaying = playing
        }
    }
}

struct SessionDetailView: View {
    let session: TestSession
    let audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Session Info
                    sessionInfoSection
                    
                    // Recording Segments
                    recordingSegmentsSection
                    
                    // GPS Coordinates
                    if session.startCoordinate != nil || session.endCoordinate != nil {
                        gpsSection
                    }
                }
                .padding()
            }
            .navigationTitle("测试详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        audioManager.stopPlayback()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sessionInfoSection: some View {
        InfoSection(title: "测试信息") {
            InfoRow(label: "VIN", value: session.vin)
            InfoRow(label: "测试类型", value: session.tag)
            InfoRow(label: "测试ID", value: session.testExecutionId)
            InfoRow(label: "开始时间", value: formatDateTime(session.startTime))
            if let endTime = session.endTime {
                InfoRow(label: "结束时间", value: formatDateTime(endTime))
            }
            InfoRow(label: "录音段数", value: "\(session.recordingSegments.count) 段")
        }
    }
    
    private var recordingSegmentsSection: some View {
        InfoSection(title: "录音片段") {
            ForEach(session.recordingSegments, id: \.id) { segment in
                RecordingSegmentDetailRow(segment: segment, audioManager: audioManager)
            }
        }
    }
    
    private var gpsSection: some View {
        InfoSection(title: "GPS坐标") {
            if let startCoord = session.startCoordinate {
                InfoRow(
                    label: "起始位置",
                    value: String(format: "%.6f, %.6f", startCoord.latitude, startCoord.longitude)
                )
            }
            if let endCoord = session.endCoordinate {
                InfoRow(
                    label: "结束位置",
                    value: String(format: "%.6f, %.6f", endCoord.latitude, endCoord.longitude)
                )
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RecordingSegmentDetailRow: View {
    let segment: RecordingSegment
    let audioManager: AudioManager
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("片段 \(segment.segmentNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(segment.formattedTime) • \(segment.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if isPlaying {
                    audioManager.stopPlayback()
                } else {
                    _ = audioManager.startPlayback(url: segment.fileURL)
                }
            }) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .onReceive(audioManager.$isPlaying) { playing in
            isPlaying = playing
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// Keep the existing InfoRow struct
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    DrivingRecordsView()
} 
