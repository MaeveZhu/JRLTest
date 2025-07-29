import SwiftUI
import AVFoundation

struct DrivingRecordsView: View {
    @State private var records: [RecordModel] = []
    @State private var showingRecordDetail = false
    @State private var selectedRecord: RecordModel?
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if records.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
            .navigationTitle("行车记录")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadRecords()
            }
            .sheet(isPresented: $showingRecordDetail) {
                if let record = selectedRecord {
                    RecordDetailView(record: record, audioManager: audioManager)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无行车记录")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("完成测试后记录将显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordsList: some View {
        List(records) { record in
            RecordRowView(record: record, audioManager: audioManager) {
                selectedRecord = record
                showingRecordDetail = true
            }
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: "DrivingRecords"),
           let decodedRecords = try? JSONDecoder().decode([RecordModel].self, from: data) {
            records = decodedRecords.sorted { $0.timestamp > $1.timestamp }
        }
    }
}

struct RecordRowView: View {
    let record: RecordModel
    let audioManager: AudioManager
    let onTap: () -> Void
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.tag)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Play button
                Button(action: {
                    if isPlaying {
                        audioManager.stopPlayback()
                    } else {
                        _ = audioManager.startPlayback(url: record.fileURL)
                    }
                }) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(record.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("VIN: \(record.vin)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("时长: \(record.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("测试ID: \(record.testExecutionId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("查看详情") {
                    onTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // GPS coordinates preview
            VStack(alignment: .leading, spacing: 4) {
                Text("起始: \(record.startCoordinateString)")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("结束: \(record.endCoordinateString)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .onReceive(audioManager.$isPlaying) { playing in
            isPlaying = playing
        }
    }
}

struct RecordDetailView: View {
    let record: RecordModel
    let audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var playbackProgress: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Audio playback section
                    audioPlaybackSection
                    
                    // 基本信息
                    infoSection(title: "测试信息") {
                        InfoRow(label: "测试类型", value: record.tag)
                        InfoRow(label: "VIN", value: record.vin)
                        InfoRow(label: "测试ID", value: record.testExecutionId)
                        InfoRow(label: "测试时间", value: record.formattedTimestamp)
                        InfoRow(label: "录音时长", value: record.formattedDuration)
                    }
                    
                    // 里程信息
                    infoSection(title: "里程信息") {
                        InfoRow(label: "起始里程", value: "\(record.milesBefore) miles")
                        InfoRow(label: "结束里程", value: "\(record.milesAfter) miles")
                    }
                    
                    // GPS坐标 - 重点显示
                    gpsCoordinatesSection
                    
                    // 文件信息
                    infoSection(title: "文件信息") {
                        InfoRow(label: "文件名", value: record.filename)
                        InfoRow(label: "文件大小", value: record.fileSize)
                    }
                }
                .padding()
            }
            .navigationTitle("测试记录详情")
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
        .onReceive(audioManager.$isPlaying) { playing in
            isPlaying = playing
        }
        .onReceive(audioManager.$playbackProgress) { progress in
            playbackProgress = progress
        }
    }
    
    private var audioPlaybackSection: some View {
        VStack(spacing: 16) {
            Text("录音回放")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Play/Stop button
                HStack {
                    Button(action: {
                        if isPlaying {
                            audioManager.stopPlayback()
                        } else {
                            _ = audioManager.startPlayback(url: record.fileURL)
                        }
                    }) {
                        HStack {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.title2)
                            Text(isPlaying ? "停止播放" : "播放录音")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isPlaying ? Color.red : Color.blue)
                        .cornerRadius(10)
                    }
                }
                
                // Progress display
                if isPlaying {
                    HStack {
                        Text(audioManager.formatDuration(playbackProgress))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(audioManager.formatDuration(audioManager.getTotalPlaybackTime()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var gpsCoordinatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GPS坐标")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Start coordinates
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("起始位置")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(record.startCoordinateString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading, 20)
                        .foregroundColor(.green)
                }
                
                Divider()
                
                // End coordinates
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("结束位置")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(record.endCoordinateString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading, 20)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

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
