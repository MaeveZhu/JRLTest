import Foundation
import CoreLocation

struct TestSession: Identifiable, Codable {
    let id = UUID()
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
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let recognizedSpeech: String
    
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