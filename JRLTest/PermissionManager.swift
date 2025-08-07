import Foundation
import AVFoundation
import CoreLocation
import UIKit
import Speech
import Intents

/**
 * PermissionManager - Comprehensive centralized permission management for all app features
 * BEHAVIOR:
 * - Manages microphone, location, speech recognition, and SiriKit permissions
 * - Provides unified permission status checking and requesting
 * - Handles permission denial scenarios with user-friendly messages
 * - Offers settings navigation for denied permissions
 * - Provides permission status callbacks and notifications
 * EXCEPTIONS:
 * - Permission requests may be denied by user
 * - System permission dialogs may not appear in certain states
 * - Settings navigation may fail if URL is invalid
 * - SiriKit permissions may not be available on all devices
 * DEPENDENCIES:
 * - Requires AVFoundation for microphone permissions
 * - Requires CoreLocation for location permissions
 * - Requires Speech framework for speech recognition permissions
 * - Requires Intents framework for SiriKit permissions
 * - Requires UIKit for settings navigation
 */
class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    // MARK: - Published Properties
    @Published var microphonePermission: AVAudioSession.RecordPermission = .undetermined
    @Published var locationPermission: CLAuthorizationStatus = .notDetermined
    @Published var speechRecognitionPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var siriPermission: INSiriAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
        // Delay permission checks to avoid startup crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAllPermissions()
        }
    }
    
    // MARK: - Permission Status
    
    /**
     * BEHAVIOR: Checks if all required permissions are granted
     * EXCEPTIONS: None
     * RETURNS: Bool - true if all permissions granted, false otherwise
     * PARAMETERS: None
     */
    var allPermissionsGranted: Bool {
        return microphonePermission == .granted &&
               locationPermission == .authorizedWhenInUse &&
               speechRecognitionPermission == .authorized &&
               siriPermission == .authorized
    }
    
    /**
     * BEHAVIOR: Returns list of missing permission names
     * EXCEPTIONS: None
     * RETURNS: [String] - Array of missing permission names
     * PARAMETERS: None
     */
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
    
    /**
     * BEHAVIOR: Returns detailed permission status for debugging
     * EXCEPTIONS: None
     * RETURNS: String - Detailed permission status
     * PARAMETERS: None
     */
    var permissionStatusDescription: String {
        return """
        权限状态:
        - 麦克风: \(microphonePermission.description)
        - 位置: \(locationPermission.description)
        - 语音识别: \(speechRecognitionPermission.description)
        - Siri: \(siriPermission.description)
        """
    }
    
    // MARK: - Permission Checking
    
    /**
     * BEHAVIOR: Checks all permissions and updates published properties
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkLocationPermission()
        checkSpeechRecognitionPermission()
        checkSiriPermission()
    }
    
    /**
     * BEHAVIOR: Checks current microphone permission status
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func checkMicrophonePermission() {
        DispatchQueue.main.async {
            self.microphonePermission = AVAudioSession.sharedInstance().recordPermission
        }
    }
    
    /**
     * BEHAVIOR: Checks current location permission status
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func checkLocationPermission() {
        DispatchQueue.main.async {
            self.locationPermission = self.locationManager.authorizationStatus
        }
    }
    
    /**
     * BEHAVIOR: Checks current speech recognition permission status
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func checkSpeechRecognitionPermission() {
        DispatchQueue.main.async {
            self.speechRecognitionPermission = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    /**
     * BEHAVIOR: Checks current SiriKit permission status
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func checkSiriPermission() {
        DispatchQueue.main.async {
            self.siriPermission = INPreferences.siriAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Requesting
    
    /**
     * BEHAVIOR: Requests microphone permission from user
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Optional callback with permission result
     */
    func requestMicrophonePermission(completion: ((Bool) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermission = granted ? .granted : .denied
                completion?(granted)
            }
        }
    }
    
    /**
     * BEHAVIOR: Requests location permission from user
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Optional callback with permission result
     */
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
    
    /**
     * BEHAVIOR: Requests speech recognition permission from user
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Optional callback with permission result
     */
    func requestSpeechRecognitionPermission(completion: ((Bool) -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechRecognitionPermission = status
                completion?(status == .authorized)
            }
        }
    }
    
    /**
     * BEHAVIOR: Requests SiriKit permission from user
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Optional callback with permission result
     */
    func requestSiriPermission(completion: ((Bool) -> Void)? = nil) {
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                self.siriPermission = status
                completion?(status == .authorized)
            }
        }
    }
    
    /**
     * BEHAVIOR: Requests all required permissions and calls completion when done
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Callback with final permission status
     */
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
    
    // MARK: - Settings Navigation
    
    /**
     * BEHAVIOR: Opens system settings app for permission configuration
     * EXCEPTIONS: May fail if settings URL is invalid or unavailable
     * RETURNS: None
     * PARAMETERS: None
     */
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
    
    // MARK: - Permission Descriptions
    
    /**
     * BEHAVIOR: Returns description text for specific permission
     * EXCEPTIONS: None
     * RETURNS: String - Permission description text
     * PARAMETERS: permission - Permission name to get description for
     */
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
    
    /**
     * BEHAVIOR: Returns error message for missing permissions
     * EXCEPTIONS: None
     * RETURNS: String - Error message for missing permissions
     * PARAMETERS: None
     */
    func getMissingPermissionsMessage() -> String {
        let missing = missingPermissions
        if missing.isEmpty {
            return "所有权限已授权"
        } else {
            return "缺少权限: \(missing.joined(separator: ", "))"
        }
    }
    
    // MARK: - Location Manager Setup
    
    /**
     * BEHAVIOR: Sets up location manager delegate
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
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
