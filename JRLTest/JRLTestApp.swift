import SwiftUI
import CarPlay

@main
struct JRLTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var carPlayManager = CarPlayManager.shared
    @StateObject private var unifiedAudioManager = UnifiedAudioManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(carPlayManager)
                .environmentObject(unifiedAudioManager)
                .onAppear {
                    print("🚀 JRLTest app initialized with CarPlay and App Intents registered")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CarPlayConnected"))) { _ in
                    print("🚗 CarPlay: Connected notification received in main app")
                    carPlayManager.connectToCarPlay()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CarPlayDisconnected"))) { _ in
                    print("🚗 CarPlay: Disconnected notification received in main app")
                    carPlayManager.disconnectFromCarPlay()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateCarPlayInterface"))) { _ in
                    print("🚗 CarPlay: Interface update requested")
                    carPlayManager.updateCarPlayInterface()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowCarPlayRecordingStatus"))) { notification in
                    if let isRecording = notification.object as? Bool {
                        print("🚗 CarPlay: Recording status update requested: \(isRecording)")
                        carPlayManager.showRecordingStatus(isRecording: isRecording)
                    }
                }
        }
    }
}
