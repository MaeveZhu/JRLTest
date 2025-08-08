import Foundation
import CoreLocation

struct RecordModel: Identifiable, Codable {
    let id: UUID
    let filename: String
    let fileURL: URL
    let timestamp: Date
    let duration: TimeInterval
    let fileSize: String
    
    let vin: String
    let testExecutionId: String
    let tag: String
    let milesBefore: Int
    let milesAfter: Int
    
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    
    init(filename: String, fileURL: URL, vin: String, testExecutionId: String, tag: String, milesBefore: Int, milesAfter: Int, startCoordinate: CLLocationCoordinate2D?, endCoordinate: CLLocationCoordinate2D?, duration: TimeInterval = 0) {
        self.id = UUID()
        self.filename = filename
        self.fileURL = fileURL
        self.vin = vin
        self.testExecutionId = testExecutionId
        self.tag = tag
        self.milesBefore = milesBefore
        self.milesAfter = milesAfter
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.timestamp = Date()
        self.duration = duration
        self.fileSize = RecordModel.getFileSize(url: fileURL)
    }
    
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
    
    var startCoordinateString: String {
        guard let coord = startCoordinate else { return "未记录" }
        return String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
    }
    
    var endCoordinateString: String {
        guard let coord = endCoordinate else { return "未记录" }
        return String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
    }
    
    private static func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return formatFileSize(fileSize)
            }
        } catch {
            // Error getting file size
        }
        return "Unknown"
    }
    
    private static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}


