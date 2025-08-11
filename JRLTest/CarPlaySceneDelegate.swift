import UIKit
import CarPlay

@objc public class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    
    // MARK: - Properties
    private var carPlayInterfaceController: CPInterfaceController?
    
    // MARK: - CarPlay Scene Delegate Methods
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        print(" CarPlay: Interface controller connected")
        
        self.carPlayInterfaceController = interfaceController
        
        // Setup the CarPlay interface
        setupCarPlayInterface()
        
        // Post notification that CarPlay is connected
        NotificationCenter.default.post(
            name: NSNotification.Name("CarPlayConnected"),
            object: nil
        )
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, 
                                didDisconnect interfaceController: CPInterfaceController) {
        print(" CarPlay: Interface controller disconnected")
        
        self.carPlayInterfaceController = nil
        
        // Notify main app of CarPlay disconnection
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("CarPlayDisconnected"), object: nil)
        }
    }
    
    // MARK: - CarPlay Interface Setup
    
    private func setupCarPlayInterface() {
        guard let interfaceController = carPlayInterfaceController else { 
            print("❌ CarPlay: No interface controller available")
            return 
        }
        
        print("🚗 CarPlay: Setting up interface")
        
        // Create a simple list template
        let mainItems = [
            CPListItem(
                text: "MT Manager",
                detailText: "IP + 5063",
                image: UIImage(systemName: "circle.fill"),
                accessoryType: .disclosureIndicator
            ) { [weak self] _, completion in
                self?.handleStartDrivingTest(completion: completion)
            },
            
            CPListItem(
                text: "开始录音",
                detailText: "开始语音和位置记录",
                image: UIImage(systemName: "record.circle.fill"),
                accessoryType: .disclosureIndicator
            ) { [weak self] _, completion in
                self?.handleStartRecording(completion: completion)
            },
            
            CPListItem(
                text: "停止录音",
                detailText: "停止当前录音",
                image: UIImage(systemName: "stop.circle.fill"),
                accessoryType: .disclosureIndicator
            ) { [weak self] _, completion in
                self?.handleStopRecording(completion: completion)
            },
            
            CPListItem(
                text: "测试状态",
                detailText: "查看当前状态",
                image: UIImage(systemName: "info.circle.fill"),
                accessoryType: .disclosureIndicator
            ) { [weak self] _, completion in
                self?.handleShowStatus(completion: completion)
            }
        ]
        
        let mainListTemplate = CPListTemplate(title: "JRL 驾驶测试", sections: [
            CPListSection(items: mainItems)
        ])
        
        // Set the template
        interfaceController.setRootTemplate(mainListTemplate, animated: true) { success, error in
            if success {
                print("🚗 CarPlay: Main template set successfully")
            } else if let error = error {
                print("❌ CarPlay: Failed to set main template: \(error)")
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleStartDrivingTest(completion: @escaping () -> Void) {
        print("🚗 CarPlay: Start driving test requested")
        
        // Get current location if available
        let currentLocation = CarPlayIntegrationManager.shared.locationManager.currentLocation
        
        // Create quick test session
        let testSession = TestSession(
            operatorCDSID: "CARPLAY_OP",
            driverCDSID: "CARPLAY_DRIVER",
            testExecution: UUID().uuidString,
            testProcedure: "CarPlay 快速测试",
            testType: "CarPlay 测试",
            testNumber: 1,
            startCoordinate: currentLocation,
            startTime: Date()
        )
        
        // Update CarPlay manager
        Task { @MainActor in
            CarPlayIntegrationManager.shared.updateCarPlayInterface(for: testSession)
        }
        
        showSimpleAlert(title: "测试已启动", message: "驾驶测试会话已开始")
        completion()
    }
    
    private func handleStartRecording(completion: @escaping () -> Void) {
        print("🚗 CarPlay: Start recording requested")
        
        Task { @MainActor in
            CarPlayIntegrationManager.shared.startRecording()
        }
        
        showSimpleAlert(title: "录音已开始", message: "正在记录语音和位置数据")
        completion()
    }
    
    private func handleStopRecording(completion: @escaping () -> Void) {
        print("🚗 CarPlay: Stop recording requested")
        
        Task { @MainActor in
            CarPlayIntegrationManager.shared.stopRecording()
        }
        
        showSimpleAlert(title: "录音已停止", message: "录音已停止，数据已保存")
        completion()
    }
    
    private func handleShowStatus(completion: @escaping () -> Void) {
        print("🚗 CarPlay: Show status requested")
        
        Task { @MainActor in
            let statusItems = CarPlayIntegrationManager.shared.getCurrentStatusItems()
            
            let statusTemplate = CPListTemplate(title: "测试状态", sections: [
                CPListSection(items: statusItems)
            ])
            
            carPlayInterfaceController?.pushTemplate(statusTemplate, animated: true)
        }
        
        completion()
    }
    
    private func showSimpleAlert(title: String, message: String) {
        let alertTemplate = CPAlertTemplate(
            titleVariants: [title],
            actions: [CPAlertAction(title: "确定", style: .default, handler: { _ in
                // Handle confirmation
            })]
        )
        
        carPlayInterfaceController?.presentTemplate(alertTemplate, animated: true)
    }
}

// MARK: - CarPlay Template Extensions

extension CPListItem {
    convenience init(text: String, detailText: String, image: UIImage?, accessoryType: CPListItemAccessoryType = .none, handler: @escaping (any CPSelectableListItem, @escaping () -> Void) -> Void) {
        self.init(text: text, detailText: detailText, image: image)
        self.accessoryType = accessoryType
        self.handler = handler
    }
}



