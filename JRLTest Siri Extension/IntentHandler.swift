//
//  IntentHandler.swift
//  JRLTest Siri Extension
//
//  Created by whosyihan on 8/4/25.
//

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

// MARK: - App Intent Definition
struct StartDrivingTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Test"
    static var description = IntentDescription("Starts a new driving test session")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get current location
        let currentLocation = await getCurrentLocation()
        
        // Create test session (using proper TestSession structure)
        let testSession = TestSession(
            vin: "SIRI_TEST",
            testExecutionId: UUID().uuidString,
            tag: "SiriKit Test",
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
                    "Capture driving data in \(.applicationName)"
                ],
                shortTitle: "Start Recording",
                systemImageName: "record.circle"
            ),
            AppShortcut(
                intent: StopRecordingIntent(),
                phrases: [
                    "Stop driving test audio in \(.applicationName)",
                    "End test session audio in \(.applicationName)",
                    "Stop capturing driving data in \(.applicationName)"
                ],
                shortTitle: "Stop Recording",
                systemImageName: "stop.circle"
            )
        ]
    }
}
