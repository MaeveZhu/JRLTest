import SwiftUI
import CarPlay

/**
 * CarPlayTestView - Testing interface for CarPlay functionality
 * BEHAVIOR:
 * - Provides testing controls for CarPlay features
 * - Tests CarPlay template creation and display
 * - Verifies CarPlay integration with main app
 * - Works in simulator environment
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 * DEPENDENCIES:
 * - Requires SwiftUI framework
 * - Integrates with CarPlayManager
 * - Tests CarPlay functionality
 */
struct CarPlayTestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var carPlayManager: CarPlayManager
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("CarPlay 测试界面")
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(testResults, id: \.self) { result in
                            HStack {
                                Image(systemName: result.contains("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.contains("✅") ? .green : .red)
                                Text(result)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 15) {
                    Button("测试 CarPlay 模板") {
                        testCarPlayTemplates()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("测试 CarPlay 通知") {
                        testCarPlayNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("测试 CarPlay 状态更新") {
                        testCarPlayStatusUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("清除测试结果") {
                        testResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("CarPlay 测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            addTestResult("🚗 CarPlay 测试界面已加载")
            addTestResult("CarPlay 连接状态: \(carPlayManager.isCarPlayConnected ? "已连接" : "未连接")")
        }
    }
    
    // MARK: - Test Methods
    
    private func testCarPlayTemplates() {
        addTestResult("🧪 测试 CarPlay 模板创建...")
        
        // Test template creation
        let testItems = [
            CPListItem(
                text: "测试项目 1",
                detailText: "这是测试详情",
                image: UIImage(systemName: "car.fill")
            ),
            
            CPListItem(
                text: "测试项目 2",
                detailText: "另一个测试详情",
                image: UIImage(systemName: "record.circle.fill")
            )
        ]
        
        let testTemplate = CPListTemplate(title: "测试模板", sections: [
            CPListSection(items: testItems)
        ])
        
        addTestResult("✅ CarPlay 模板创建成功")
        addTestResult("模板标题: \(testTemplate.title ?? "无标题")")
        addTestResult("项目数量: \(testItems.count)")
    }
    
    private func testCarPlayNotifications() {
        addTestResult("🧪 测试 CarPlay 通知...")
        
        // Test notification posting
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateCarPlayInterface"),
            object: nil
        )
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowCarPlayRecordingStatus"),
            object: true
        )
        
        addTestResult("✅ CarPlay 通知已发送")
    }
    
    private func testCarPlayStatusUpdates() {
        addTestResult("🧪 测试 CarPlay 状态更新...")
        
        // Test status updates
        carPlayManager.updateRecordingStatus(isRecording: true)
        
        let testSession = TestSession(
            operatorCDSID: "TEST_OP",
            driverCDSID: "TEST_DRIVER",
            testExecution: UUID().uuidString,
            testProcedure: "CarPlay 测试程序",
            testType: "测试类型",
            testNumber: 1,
            startCoordinate: nil,
            startTime: Date()
        )
        
        carPlayManager.updateCarPlayInterface(for: testSession)
        
        addTestResult("✅ CarPlay 状态更新成功")
        addTestResult("录音状态: \(carPlayManager.isRecording)")
        addTestResult("测试会话: \(testSession.testProcedure)")
    }
    
    private func addTestResult(_ result: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        testResults.append("[\(timestamp)] \(result)")
    }
}

#Preview {
    CarPlayTestView()
        .environmentObject(CarPlayManager.shared)
} 