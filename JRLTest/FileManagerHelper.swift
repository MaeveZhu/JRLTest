import Foundation
import CoreLocation

class FileManagerHelper {
    
    // 生成带坐标和时间戳的文件名
    static func generateFilename(with coordinate: CLLocationCoordinate2D) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let lat = String(format: "%.6f", coordinate.latitude)
        let lon = String(format: "%.6f", coordinate.longitude)
        return "record_\(lat)_\(lon)_\(timestamp).m4a"
    }
    
    // 获取录音文件保存路径
    static func recordingURL(filename: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        
        // 创建Recordings目录（如果不存在）
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
        
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    // 获取所有录音文件
    static func getAllRecordings() -> [URL] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        } catch {
            print("获取录音文件失败: \(error)")
            return []
        }
    }
    
    // 从文件名解析坐标信息
    static func parseCoordinateFromFilename(_ filename: String) -> CLLocationCoordinate2D? {
        let components = filename.replacingOccurrences(of: ".m4a", with: "").components(separatedBy: "_")
        
        guard components.count >= 4,
              let latString = components.dropFirst().first,
              let lonString = components.dropFirst(2).first,
              let lat = Double(latString),
              let lon = Double(lonString) else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // 获取文件大小
    static func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("获取文件大小失败: \(error)")
        }
        return "未知"
    }
    
    // 删除录音文件
    static func deleteRecording(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("删除文件失败: \(error)")
            return false
        }
    }
} 