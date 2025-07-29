import SwiftUI
import AVFoundation

struct SimpleVoiceRecordView: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var recordings: [RecordModel] = []
    @State private var showingRecordingsList = false
    @State private var showingPlaybackAlert = false
    @State private var selectedRecording: RecordModel?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("语音录音")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 录音状态
            if audioManager.isRecording {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .scaleEffect(1.2)
                    Text("录音中: \(audioManager.formatDuration(audioManager.recordingDuration))")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            // 录音按钮
            Button(action: {
                print("录音按钮被点击")
                if audioManager.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                VStack(spacing: 10) {
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(audioManager.isRecording ? "停止录音" : "开始录音")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 300, height: 300)
                .background(audioManager.isRecording ? Color.red : Color.blue)
                .cornerRadius(150)
                .shadow(radius: 10)
            }
            
            Spacer()
            
            // 录音列表按钮
            Button(action: {
                print("录音列表按钮被点击")
                loadRecordings()
                showingRecordingsList = true
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                    Text("录音列表 (\(recordings.count))")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
        .padding()
        .alert("录音状态", isPresented: .constant(audioManager.errorMessage != nil)) {
            Button("确定") {
                audioManager.clearError()
            }
        } message: {
            if let errorMessage = audioManager.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingRecordingsList) {
            RecordingsListView(recordings: recordings) { recording in
                selectedRecording = recording
                showingPlaybackAlert = true
            }
        }
        .alert("播放录音", isPresented: $showingPlaybackAlert) {
            Button("播放") {
                if let recording = selectedRecording {
                    audioManager.startPlayback(url: recording.fileURL)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            if let recording = selectedRecording {
                Text("播放录音文件: \(recording.filename)")
            }
        }
        .onAppear {
            loadRecordings()
        }
    }
    
    private func loadRecordings() {
        // Load from DrivingRecords instead of old SavedRecordings
        if let data = UserDefaults.standard.data(forKey: "DrivingRecords"),
           let decodedRecordings = try? JSONDecoder().decode([RecordModel].self, from: data) {
            recordings = decodedRecordings
        } else {
            recordings = []
        }
        print("加载录音列表: \(recordings.count) 个录音文件")
    }
    
    private func startRecording() {
        print("=== 开始录音函数被调用 ===")
        
        // Request permission if needed
        audioManager.requestMicrophonePermission { granted in
            if granted {
                DispatchQueue.main.async {
                    if self.audioManager.startRecording() {
                        print("✅ 录音开始成功")
                    } else {
                        print("❌ 录音开始失败")
                    }
                }
            } else {
                print("❌ 麦克风权限被拒绝")
            }
        }
    }
    
    private func stopRecording() {
        print("=== 停止录音函数被调用 ===")
        
        if let recordingURL = audioManager.stopRecording() {
            print("✅ 录音已保存: \(recordingURL)")
            loadRecordings() // 重新加载录音列表
        } else {
            print("❌ 录音保存失败")
        }
    }
}

// MARK: - Recordings List View
struct RecordingsListView: View {
    let recordings: [RecordModel]
    let onRecordingSelected: (RecordModel) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(recordings) { recording in
                RecordingRowView(recording: recording) {
                    onRecordingSelected(recording)
                    dismiss()
                }
            }
            .navigationTitle("录音列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recording Row View
struct RecordingRowView: View {
    let recording: RecordModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(recording.filename)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("时长: \(recording.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Update to show VIN and test info if available, otherwise show coordinates
                    if !recording.vin.isEmpty {
                        Text("VIN: \(recording.vin)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("测试: \(recording.tag)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("起始位置: \(recording.startCoordinateString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("时间: \(recording.formattedTimestamp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
