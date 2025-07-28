import Foundation
import CoreLocation

struct RecordModel: Identifiable, Codable {
    let id = UUID()
    let filename: String
    let fileURL: URL
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let duration: TimeInterval
    let fileSize: String
    
    init(filename: String, fileURL: URL, coordinate: CLLocationCoordinate2D, duration: TimeInterval = 0) {
        self.filename = filename
        self.fileURL = fileURL
        self.coordinate = coordinate
        self.timestamp = Date()
        self.duration = duration
        self.fileSize = FileManagerHelper.getFileSize(url: fileURL)
    }
    
    // 格式化显示信息
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var coordinateString: String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
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