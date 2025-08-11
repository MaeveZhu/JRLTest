import UIKit
import SwiftUI
import CarPlay

class AppDelegate: NSObject, UIApplicationDelegate, CPTemplateApplicationSceneDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🚀 App Delegate: Application did finish launching")
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("🚀 App Delegate: Configuration for connecting scene session with role: \(connectingSceneSession.role)")
        
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay Template Configuration", sessionRole: .carTemplateApplication)
            config.delegateClass = AppDelegate.self
            return config
        } else {
            let config = UISceneConfiguration(name: "Default Configuration", sessionRole: .windowApplication)
            config.delegateClass = SceneDelegate.self
            return config
        }
    }
    
    // MARK: - CarPlay Scene Delegate Methods
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        print(" CarPlay: Interface controller connected")
        setupCarPlayInterface(interfaceController)
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, 
                                didDisconnect interfaceController: CPInterfaceController) {
        print(" CarPlay: Interface controller disconnected")
    }
    
    private func setupCarPlayInterface(_ interfaceController: CPInterfaceController) {
        // Your CarPlay interface setup code here
        let mainItems = [
            CPListItem(
                text: "MT Manager",
                detailText: "启动MT Manager",
                image: UIImage(systemName: "car.fill")
            ) { _, completion in
                print("准备启动")
                completion()
            }
        ]
        
        let mainListTemplate = CPListTemplate(title: "JRL 驾驶测试", sections: [
            CPListSection(items: mainItems)
        ])
        
        interfaceController.setRootTemplate(mainListTemplate, animated: true)
    }
}
