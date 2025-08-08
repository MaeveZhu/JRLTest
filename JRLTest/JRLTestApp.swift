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
        // Set up crash prevention
        setupCrashPrevention()
        
        // Register App Shortcuts for Siri
        DrivingTestShortcuts.updateAppShortcutParameters()
        print("🚀 JRLTest app initialized with App Intents registered")
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
                        print("🔄 App shortcuts re-registered on app activation")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SiriDrivingTestStarted"))) { notification in
                    // Handle Siri-initiated driving test
                    handleSiriDrivingTestStarted(notification)
                }
        }
    }
    
    /**
     * BEHAVIOR: Sets up global exception and signal handlers for crash prevention
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    private func setupCrashPrevention() {
        // Set up global exception handling
        NSSetUncaughtExceptionHandler { exception in
            print("Uncaught exception: \(exception)")
            print("Stack trace: \(exception.callStackSymbols)")
        }
        
        // Set up signal handling for abort signals
        signal(SIGABRT) { signal in
            print("Received SIGABRT signal: \(signal)")
        }
        
        signal(SIGSEGV) { signal in
            print("Received SIGSEGV signal: \(signal)")
        }
    }
    
    /**
     * BEHAVIOR: Handles app activation by re-checking location permissions
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    private func handleAppBecameActive() {
        // Re-check permissions when app becomes active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            permissionManager.checkLocationPermission()
        }
    }
    
    /**
     * BEHAVIOR: Handles Siri-initiated driving test session
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: notification - The notification containing test session data
     */
    private func handleSiriDrivingTestStarted(_ notification: Notification) {
        print("🎤 Siri driving test started!")
        if let testSession = notification.object {
            print("Test session: \(testSession)")
            // You can navigate to a specific view or update UI here
        }
    }
}

// MARK: - App Intents (moved from Siri Extension for proper registration)

// MARK: - App Intent Definitions
struct StartDrivingTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Test"
    static var description = IntentDescription("Starts a new driving test session")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🎤 StartDrivingTestIntent: perform() called")
        
        // Get current location
        let currentLocation = await getCurrentLocation()
        
        // Create test session (using proper TestSession structure)
        let testSession = TestSession(
            operatorCDSID: "SIRI_TEST",
            driverCDSID: UUID().uuidString,
            testExecution: UUID().uuidString,
            testProcedure: "SiriKit Test",
            testType: "SiriKit Test",
            testNumber: 1,
            startCoordinate: currentLocation,
            startTime: Date()
        )
        
        // Post notification to update UI in main app and start recording
        DispatchQueue.main.async {
            print("🎤 StartDrivingTestIntent: Posting SiriDrivingTestStarted notification")
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
        print("🎤 StartRecordingIntent: perform() called")
        
        // Post notification to start recording
        DispatchQueue.main.async {
            print("🎤 StartRecordingIntent: Posting SiriStartRecording notification")
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
        print("🛑 StopRecordingIntent: perform() called")
        
        // Post notification to stop recording
        DispatchQueue.main.async {
            print("🛑 StopRecordingIntent: Posting SiriStopRecording notification")
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
