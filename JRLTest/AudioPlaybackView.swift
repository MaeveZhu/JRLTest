import SwiftUI
import AVFoundation

struct AudioPlaybackView: View {
    let audioURL: URL
    @StateObject private var audioPlayer = AudioPlayer()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 标题
                Text("录音播放")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 音频信息
                VStack(spacing: 15) {
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("录音文件")
                        .font(.headline)
                    
                    Text(audioURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                
                // 播放控制
                VStack(spacing: 20) {
                    // 播放进度
                    if audioPlayer.duration > 0 {
                        VStack(spacing: 10) {
                            HStack {
                                Text(formatTime(audioPlayer.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(formatTime(audioPlayer.duration))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    // 播放按钮
                    Button(action: {
                        if audioPlayer.isPlaying {
                            audioPlayer.stop()
                        } else {
                            audioPlayer.play(url: audioURL)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                                .font(.title2)
                            Text(audioPlayer.isPlaying ? "停止" : "播放")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(audioPlayer.isPlaying ? Color.red : Color.green)
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
                
                // 确认按钮
                VStack(spacing: 15) {
                    Text("确认录音质量")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        Button("重新录音") {
                            audioPlayer.stop()
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                        
                        Button("确认录音") {
                            audioPlayer.stop()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("播放录音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        audioPlayer.stop()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AudioPlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        AudioPlaybackView(audioURL: URL(fileURLWithPath: "/test/recording.m4a"))
    }
} 