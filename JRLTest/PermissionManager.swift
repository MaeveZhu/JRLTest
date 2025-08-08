import Foundation
import AVFoundation
import CoreLocation
import UIKit
import Speech
import Intents

class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    @Published var microphonePermission: AVAudioSession.RecordPermission = .undetermined
    @Published var locationPermission: CLAuthorizationStatus = .notDetermined
    @Published var speechRecognitionPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var siriPermission: INSiriAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAllPermissions()
        }
    }
    
    var allPermissionsGranted: Bool {
        return microphonePermission == .granted &&
               locationPermission == .authorizedWhenInUse &&
               speechRecognitionPermission == .authorized &&
               siriPermission == .authorized
    }
    
    var missingPermissions: [String] {
        var missing: [String] = []
        
        if microphonePermission != .granted {
            missing.append("麦克风")
        }
        
        if locationPermission != .authorizedWhenInUse {
            missing.append("位置")
        }
        
        if speechRecognitionPermission != .authorized {
            missing.append("语音识别")
        }
        
        if siriPermission != .authorized {
            missing.append("Siri")
        }
        
        return missing
    }
    
    var permissionStatusDescription: String {
        return """
        权限状态:
        - 麦克风: \(microphonePermission.description)
        - 位置: \(locationPermission.description)
        - 语音识别: \(speechRecognitionPermission.description)
        - Siri: \(siriPermission.description)
        """
    }
    
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkLocationPermission()
        checkSpeechRecognitionPermission()
        checkSiriPermission()
    }
    
    func checkMicrophonePermission() {
        DispatchQueue.main.async {
            self.microphonePermission = AVAudioSession.sharedInstance().recordPermission
        }
    }
    
    func checkLocationPermission() {
        DispatchQueue.main.async {
            self.locationPermission = self.locationManager.authorizationStatus
        }
    }
    
    func checkSpeechRecognitionPermission() {
        DispatchQueue.main.async {
            self.speechRecognitionPermission = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    func checkSiriPermission() {
        DispatchQueue.main.async {
            self.siriPermission = INPreferences.siriAuthorizationStatus()
        }
    }
    
    func requestMicrophonePermission(completion: ((Bool) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermission = granted ? .granted : .denied
                completion?(granted)
            }
        }
    }
    
    func requestLocationPermission(completion: ((Bool) -> Void)? = nil) {
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // The result will be handled by the delegate
            completion?(true) // Assume granted for now
        case .authorizedWhenInUse, .authorizedAlways:
            completion?(true)
        case .denied, .restricted:
            completion?(false)
        @unknown default:
            completion?(false)
        }
    }
    
    func requestSpeechRecognitionPermission(completion: ((Bool) -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechRecognitionPermission = status
                completion?(status == .authorized)
            }
        }
    }
    
    func requestSiriPermission(completion: ((Bool) -> Void)? = nil) {
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                self.siriPermission = status
                completion?(status == .authorized)
            }
        }
    }
    
    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        var completedPermissions = 0
        let totalPermissions = 4
        
        let checkCompletion = {
            completedPermissions += 1
            if completedPermissions == totalPermissions {
                completion(self.allPermissionsGranted)
            }
        }
        
        // Request microphone permission
        requestMicrophonePermission { _ in
            checkCompletion()
        }
        
        // Request location permission
        requestLocationPermission { _ in
            checkCompletion()
        }
        
        // Request speech recognition permission
        requestSpeechRecognitionPermission { _ in
            checkCompletion()
        }
        
        // Request Siri permission
        requestSiriPermission { _ in
            checkCompletion()
        }
    }
    
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { _ in
                // Re-check permissions after settings page closes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkAllPermissions()
                }
            }
        }
    }
    
    func getPermissionDescription(for permission: String) -> String {
        switch permission {
        case "麦克风":
            return "需要麦克风权限来录制语音和进行语音识别。请在设置中开启麦克风访问权限。"
        case "位置":
            return "需要定位权限来记录测试时的GPS坐标。请在设置中开启定位服务权限。"
        case "语音识别":
            return "需要语音识别权限来进行语音转文字功能。请在设置中开启语音识别权限。"
        case "Siri":
            return "需要Siri权限来使用语音命令控制录音功能。请在设置中开启Siri权限。"
        default:
            return "未知权限"
        }
    }
    
    func getMissingPermissionsMessage() -> String {
        let missing = missingPermissions
        if missing.isEmpty {
            return "所有权限已授权"
        } else {
            return "缺少权限: \(missing.joined(separator: ", "))"
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    /**
     * BEHAVIOR: Handles location authorization status changes
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: 
     * - manager: CLLocationManager instance
     * - status: New authorization status
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationPermission = status
        }
    }
}

// MARK: - Permission Status Extensions
extension AVAudioSession.RecordPermission {
    var description: String {
        switch self {
        case .granted:
            return "已授权"
        case .denied:
            return "已拒绝"
        case .undetermined:
            return "未确定"
        @unknown default:
            return "未知"
        }
    }
}

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终授权"
        case .authorizedWhenInUse:
            return "使用时授权"
        @unknown default:
            return "未知"
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .authorized:
            return "已授权"
        @unknown default:
            return "未知"
        }
    }
}

extension INSiriAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .authorized:
            return "已授权"
        @unknown default:
            return "未知"
        }
    }
} 
