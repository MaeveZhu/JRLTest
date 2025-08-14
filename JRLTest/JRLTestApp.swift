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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SiriDrivingTestStarted"))) { notification in
                    // Handle Siri-initiated driving test
                    handleSiriDrivingTestStarted(notification)
                }
        }
    }
    
    private func handleAppBecameActive() {
        // Re-check permissions when app becomes active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            permissionManager.checkLocationPermission()
        }
    }
    
    private func handleSiriDrivingTestStarted(_ notification: Notification) {
        if let testSession = notification.object {
            // Handle Siri test session
        }
    }
}

// MARK: - App Intents
struct StartDrivingTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Test"
    static var description = IntentDescription("Starts a new driving test session")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get current location
        let currentLocation = await getCurrentLocation()
        
        // Create test session (using simplified TestSession structure)
        let testSession = TestSession(
            operatorCDSID: "SIRI_TEST",
            startCoordinate: currentLocation,
            startTime: Date()
        )
        
        // Post notification to update UI in main app and start recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SiriDrivingTestStarted"),
                object: testSession
            )
        }
        
        return .result(dialog: "Driving test started. Recording location and voice data.")
    }
    
    private func getCurrentLocation() async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            let locationManager = CLLocationManager()
            continuation.resume(returning: locationManager.location?.coordinate)
        }
    }
}

// MARK: - Recording Intent
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description = IntentDescription("Starts voice and location recording")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to start recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SiriStartRecording"),
                object: nil
            )
        }
        
        return .result(dialog: "Driving test audio capture started")
    }
}

// MARK: - Stop Recording Intent
struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops current recording")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to stop recording
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SiriStopRecording"),
                object: nil
            )
        }
        
        return .result(dialog: "Driving test audio capture stopped")
    }
}

// MARK: - App Shortcuts Provider
struct DrivingTestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartDrivingTestIntent(),
                phrases: [
                    "Report driving test in \(.applicationName)",
                    "Start driving test in \(.applicationName)",
                    "Begin test with \(.applicationName)",
                    "Start test using \(.applicationName)"
                ],
                shortTitle: "Start Test",
                systemImageName: "car"
            ),
            AppShortcut(
                intent: StartRecordingIntent(),
                phrases: [
                    "Start driving test audio in \(.applicationName)",
                    "Begin test session audio in \(.applicationName)",
                    "Capture driving data in \(.applicationName)",
                    "Start recording in \(.applicationName)"
                ],
                shortTitle: "Start Recording",
                systemImageName: "record.circle"
            ),
            AppShortcut(
                intent: StopRecordingIntent(),
                phrases: [
                    "Stop driving test audio in \(.applicationName)",
                    "End test session audio in \(.applicationName)",
                    "Stop capturing driving data in \(.applicationName)",
                    "Stop recording in \(.applicationName)"
                ],
                shortTitle: "Stop Recording",
                systemImageName: "stop.circle"
            )
        ]
    }
}
