import UIKit
import SwiftUI

/**
 * SceneDelegate - Manages iOS app scene lifecycle
 * BEHAVIOR:
 * - Handles iOS app scene configuration
 * - Manages window and view controller lifecycle
 * - Integrates with existing SwiftUI app structure
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 * DEPENDENCIES:
 * - Requires UIKit framework
 * - Integrates with existing SwiftUI ContentView
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Properties
    var window: UIWindow?
    
    // MARK: - Scene Lifecycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        print("🚀 iOS Scene: Scene will connect")
        
        // Create window for iOS app
        let window = UIWindow(windowScene: windowScene)
        
        // Create SwiftUI content view
        let contentView = ContentView()
            .environmentObject(CarPlayManager.shared)
        
        // Set root view controller
        let hostingController = UIHostingController(rootView: contentView)
        window.rootViewController = hostingController
        
        self.window = window
        window.makeKeyAndVisible()
        
        print("🚀 iOS Scene: Window created and made key")
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("🚀 iOS Scene: Scene did disconnect")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("🚀 iOS Scene: Scene did become active")
        
        // Handle app becoming active
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        print("🚀 iOS Scene: Scene will resign active")
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("🚀 iOS Scene: Scene will enter foreground")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("🚀 iOS Scene: Scene did enter background")
    }
    
    // MARK: - Scene Configuration
    
    func windowScene(_ windowScene: UIWindowScene, didUpdate oldCoordinateSpace: UICoordinateSpace, interfaceOrientation oldInterfaceOrientation: UIInterfaceOrientation, traitCollection oldTraitCollection: UITraitCollection) {
        print("🚀 iOS Scene: Window scene did update coordinate space")
    }
} 
