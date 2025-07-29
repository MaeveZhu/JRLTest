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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerSection
                
                Spacer()
                
                statusIndicator
                
                Spacer()
                
                instructionsSection
                
                if !voiceManager.recordingSegments.isEmpty {
                    recordingSegmentsSection
                }
                
                Spacer()
                
                endTestButton
            }
            .padding()
            .navigationTitle("语音控制测试")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            startAutoVoiceTest()
        }
        .onDisappear {
            voiceManager.stopListening()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("自动语音测试已启动")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("VIN: \(vin)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("测试类型: \(tag)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 20) {
            // 监听状态
            HStack {
                Circle()
                    .fill(voiceManager.isListening ? Color.green : Color.gray)
                    .frame(width: 16, height: 16)
                
                Text(voiceManager.isListening ? "🎤 正在监听语音命令..." : "⏸️ 语音监听已暂停")
                    .font(.headline)
                    .foregroundColor(voiceManager.isListening ? .green : .gray)
            }
            
            // 录音状态
            if voiceManager.isRecording {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "record.circle.fill")
                            .foregroundColor(.red)
                            .scaleEffect(1.5)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: voiceManager.isRecording)
                        
                        Text("正在录音片段 \(voiceManager.recordingSegments.count + 1)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Text("保持3秒静音将自动停止录音")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(spacing: 15) {
            Text("说出以下任一命令开始录音:")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                TriggerWordRow(text: "\"Hey Siri\"", icon: "mic.fill")
                TriggerWordRow(text: "\"开始记录\"", icon: "record.circle")
                TriggerWordRow(text: "\"开始录音\"", icon: "waveform")
            }
            
            Text("• 每次命令创建一个新的录音片段\n• 3秒静音自动结束当前片段\n• 可以多次录音")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var recordingSegmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("已录制片段: \(voiceManager.recordingSegments.count)")
                .font(.headline)
                .foregroundColor(.green)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(voiceManager.recordingSegments, id: \.id) { segment in
                        VStack(spacing: 4) {
                            Text("片段 \(segment.segmentNumber)")
                                .font(.caption2)
                                .fontWeight(.bold)
                            
                            Text(segment.formattedDuration)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var endTestButton: some View {
        Button("结束测试") {
            endVoiceTest()
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func startAutoVoiceTest() {
        print("🚀 启动自动语音测试...")
        voiceManager.startTestSession(
            vin: vin,
            testExecutionId: testExecutionId,
            tag: tag,
            startCoordinate: startCoordinate
        )
    }
    
    private func endVoiceTest() {
        let endCoordinate = locationManager.currentLocation
        let _ = voiceManager.endTestSession(endCoordinate: endCoordinate)
        
        showingResultsView = true
        dismiss()
    }
}

struct TriggerWordRow: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
}

#Preview {
    AutoVoiceTestView(
        vin: "TEST123",
        testExecutionId: "EXEC001", 
        tag: "Engine Test",
        startCoordinate: nil,
        showingResultsView: .constant(false)
    )
} 