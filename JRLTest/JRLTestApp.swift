import SwiftUI
import AppIntents
import CoreLocation

/**
 * JRLTestApp - Main application entry point
 * BEHAVIOR:
 * - Initializes the SwiftUI app lifecycle
 * - Sets up global crash prevention mechanisms
 * - Manages app state transitions
 * - Handles permission management on app activation
 * EXCEPTIONS:
 * - Global exception handler may not catch all crashes
 * - Signal handlers may not work in all scenarios
 * - Permission checks may fail on app activation
 * DEPENDENCIES:
 * - Requires SwiftUI framework
 * - Uses PermissionManager for permission handling
 * - Requires system signal handling capabilities
 */
@main
struct JRLTestApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    
    init() {
        // Register App Shortcuts for Siri
        DrivingTestShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Handle app becoming active
                    handleAppBecameActive()
                    
                    // Re-register shortcuts when app becomes active
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        DrivingTestShortcuts.updateAppShortcutParameters()
                    }
                }
        }
    }
    
    private func handleAppBecameActive() {
        // Re-check permissions when app becomes active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            permissionManager.checkLocationPermission()
        }
    }
}

// MARK: - App Intents
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description = IntentDescription("Starts voice and location recording")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to start recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("StartRecording"),
                object: nil
            )
        }
        
    return .result(dialog: IntentDialog(stringLiteral: "Voice recording started"))    }
}

struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops current recording")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to stop recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("StopRecording"),
                object: nil
            )
        }
        
    return .result(dialog: IntentDialog(stringLiteral: "Voice recording stopped"))    }
}

struct StartReportingIntent: AppIntent {
    static var title: LocalizedStringResource = "开始汇报测试结果"
    static var description = IntentDescription("开始记录新的测试段")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🎯 StartReportingIntent.perform() called")
        
        // Get current session info
        let carTestManager = CarTestManager.shared
        let currentSegmentNumber = carTestManager.getCurrentSegmentNumber()
        
        // Post notification to start recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("StartRecording"),
                object: nil
            )
        }
        
        let dialogMessage = "已开始记录第\(currentSegmentNumber)段测试"
        print("🎯 StartReportingIntent: \(dialogMessage)")
        
    return .result(dialog: IntentDialog(stringLiteral: dialogMessage))    }
}

// MARK: - App Shortcuts Provider
struct DrivingTestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartRecordingIntent(),
                phrases: [
                    "开始汽车测试录音\(.applicationName)",
                    "Begin recording in \(.applicationName)",
                    "Start voice recording in \(.applicationName)"
                ],
                shortTitle: "Start Recording",
                systemImageName: "record.circle"
            ),
            AppShortcut(
                intent: StopRecordingIntent(),
                phrases: [
                    "停止汽车测试录音\(.applicationName)",                    // Chinese
                ],
                shortTitle: "Stop Recording",
                systemImageName: "stop.circle"
            ),
            AppShortcut(
                intent: StartReportingIntent(),
                phrases: [
                    "在\(.applicationName)中开始汇报测试结果",
                    "开始汇报测试结果\(.applicationName)",
                    "Start reporting test results in \(.applicationName)"
                ],
                shortTitle: "开始汇报",
                systemImageName: "mic.circle"
            )
        ]
    }
}
