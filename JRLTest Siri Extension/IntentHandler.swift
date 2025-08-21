
import AppIntents
import CoreLocation

// MARK: - Test Session Model (shared with main app)
struct TestSession: Identifiable, Codable {
    let id = UUID()
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    let startTime: Date
    var endTime: Date?
    var recordingSegments: [RecordingSegment] = []
}

struct RecordingSegment: Identifiable, Codable {
    let id: UUID
    let segmentNumber: Int
    let fileName: String
    let fileURL: URL
    let startTime: Date
    let endTime: Date
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let recognizedSpeech: String
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - App Intent Definitions
struct StartDrivingTestAudioIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Test Audio"
    static var description = IntentDescription("Starts voice and location recording for driving test")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🎤 StartDrivingTestAudioIntent: perform() called")
        
        // Post notification to start recording with coordinate
        DispatchQueue.main.async {
            print("🎤 StartDrivingTestAudioIntent: Posting SiriStartRecording notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("SiriStartRecording"),
                object: nil
            )
        }
        
        return .result(dialog: "Driving test audio recording started")
    }
}

struct StopDrivingTestAudioIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Driving Test Audio"
    static var description = IntentDescription("Stops current voice and location recording")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🛑 StopDrivingTestAudioIntent: perform() called")
        
        // Post notification to stop recording
        DispatchQueue.main.async {
            print("🛑 StopDrivingTestAudioIntent: Posting SiriStopRecording notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("SiriStopRecording"),
                object: nil
            )
        }
        
        return .result(dialog: "Driving test audio recording stopped")
    }
}

// MARK: - App Shortcuts Provider
struct DrivingTestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartDrivingTestAudioIntent(),
                phrases: [
                    "Start driving test audio in \(.applicationName)",
                    "Begin test session audio in \(.applicationName)",
                    "Capture driving data in \(.applicationName)",
                    "Start recording in \(.applicationName)"
                ],
                shortTitle: "Start Audio Recording",
                systemImageName: "record.circle"
            ),
            AppShortcut(
                intent: StopDrivingTestAudioIntent(),
                phrases: [
                    "Stop driving test audio in \(.applicationName)",
                    "End test session audio in \(.applicationName)",
                    "Stop recording in \(.applicationName)",
                    "Stop capturing driving data in \(.applicationName)"
                ],
                shortTitle: "Stop Audio Recording",
                systemImageName: "stop.circle"
            )
        ]
    }
}
