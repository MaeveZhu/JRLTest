import Foundation
import AppIntents

// MARK: - Start Driving Test Intent
struct StartDrivingTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Test"
    static var description: LocalizedStringResource = "Start a new driving test session"
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the main app
        return .result()
    }
}

// MARK: - Start Recording Intent
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description: LocalizedStringResource = "Start recording audio and location"
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the main app
        return .result()
    }
}

// MARK: - Stop Recording Intent
struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description: LocalizedStringResource = "Stop current recording"
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the main app
        return .result()
    }
}

    
    // Add this method if the above still doesn't work
var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartDrivingTestIntent(),
                phrases: ["Start driving test", "Begin test", "Start test session"]
            ),
            AppShortcut(
                intent: StartRecordingIntent(),
                phrases: ["Start recording", "Begin recording", "Record audio"]
            ),
            AppShortcut(
                intent: StopRecordingIntent(),
                phrases: ["Stop recording", "End recording", "Stop audio"]
            )
        ]
    }
