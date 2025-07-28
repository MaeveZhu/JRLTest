import Foundation
import CoreLocation
import UIKit // Added for UIDevice

class FirebaseVoiceStorageService: VoiceStorageService {
    
    // 存储录音文件的元数据
    private var recordingMetadata: [String: Any] = [:]
    
    func uploadVoiceRecording(fileURL: URL, metadata: [String: Any], completion: @escaping (Result<URL, Error>) -> Void) {
        // 合并元数据
        var fullMetadata = metadata
        fullMetadata["uploadTimestamp"] = Date().timeIntervalSince1970
        fullMetadata["deviceID"] = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        // TODO: 实现Firebase Storage上传逻辑
        // 1. 创建Firebase Storage引用
        // 2. 上传音频文件
        // 3. 保存元数据到Firestore
        // 4. 返回下载URL
        
        print("准备上传录音文件: \(fileURL.lastPathComponent)")
        print("元数据: \(fullMetadata)")
        
        // 模拟上传成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success(fileURL))
        }
    }
    
    // 为语音触发录音添加专门的元数据
    func prepareVoiceTriggerMetadata(coordinate: CLLocationCoordinate2D, triggerText: String) -> [String: Any] {
        return [
            "triggerType": "voice",
            "triggerText": triggerText,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "recordingStartTime": Date().timeIntervalSince1970,
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
    }
}

// MARK: - 扩展VoiceStorageService协议
extension VoiceStorageService {
    func uploadVoiceTriggeredRecording(fileURL: URL, coordinate: CLLocationCoordinate2D, triggerText: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let metadata = [
            "triggerType": "voice",
            "triggerText": triggerText,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "recordingStartTime": Date().timeIntervalSince1970
        ] as [String : Any]
        
        uploadVoiceRecording(fileURL: fileURL, metadata: metadata, completion: completion)
    }
} 
