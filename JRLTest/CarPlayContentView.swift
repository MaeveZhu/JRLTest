import SwiftUI
import CarPlay

/**
 * CarPlayContentView - SwiftUI view for CarPlay interface
 * BEHAVIOR:
 * - Provides SwiftUI wrapper for CarPlay templates
 * - Handles CarPlay-specific UI interactions
 * - Integrates with existing app functionality
 * - Works in simulator environment
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 * DEPENDENCIES:
 * - Requires SwiftUI framework
 * - Integrates with CarPlayManager
 * - Uses existing app models and managers
 */
struct CarPlayContentView: View {
    @EnvironmentObject var carPlayManager: CarPlayManager
    @State private var showingCarPlayInterface = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("CarPlay 接口")
                .font(.title)
                .fontWeight(.bold)
            
            Text("CarPlay 已连接")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(carPlayManager.isRecording ? .red : .gray)
                    Text("录音状态:")
                    Text(carPlayManager.isRecording ? "正在录音" : "未录音")
                        .foregroundColor(carPlayManager.isRecording ? .red : .gray)
                }
                
                if let testSession = carPlayManager.currentTestSession {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                        Text("测试会话:")
                        Text(testSession.testProcedure)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Button("刷新 CarPlay 界面") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateCarPlayInterface"),
                    object: nil
                )
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            print("🚗 CarPlayContentView appeared")
            // Notify that CarPlay view is active
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CarPlayViewActive"),
                    object: nil
                )
            }
        }
    }
}

#Preview {
    CarPlayContentView()
        .environmentObject(CarPlayManager.shared)
} 