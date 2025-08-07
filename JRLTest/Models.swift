import Foundation
import CoreLocation

/**
 * TestSession - Represents a complete test session with recordings
 * 
 * BEHAVIOR:
 * - Stores test session metadata including VIN, coordinates, and timing
 * - Contains array of recording segments for the session
 * - Supports Codable for persistence
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
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

/**
 * RecordingSegment - Represents a single audio recording segment
 * 
 * BEHAVIOR:
 * - Stores metadata for individual recording segments
 * - Provides formatted duration and time strings
 * - Supports Codable for persistence
 * 
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
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
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

// MARK: - CLLocationCoordinate2D Codable
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