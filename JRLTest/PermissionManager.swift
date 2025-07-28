import Foundation
import AVFoundation
import CoreLocation
import UIKit
import Speech

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var microphonePermission: AVAudioSession.RecordPermission = .undetermined
    @Published var locationPermission: CLAuthorizationStatus = .notDetermined
    @Published var speechRecognitionPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private init() {
        checkLocationPermission()
    }
    
    var allPermissionsGranted: Bool {
        return microphonePermission == .granted &&
               locationPermission == .authorizedWhenInUse &&
               speechRecognitionPermission == .authorized
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
        
        return missing
    }
    
    func checkMicrophonePermission() {
        DispatchQueue.main.async {
            // For now, we'll assume undetermined and let the request function handle the actual status
            self.microphonePermission = .undetermined
        }
    }
    
    private func convertToSessionPermission(_ granted: Bool) -> AVAudioSession.RecordPermission {
        return granted ? .granted : .denied
    }
    
    func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermission = self.convertToSessionPermission(granted)
            }
        }
    }
    
    func checkLocationPermission() {
        DispatchQueue.main.async {
            self.locationPermission = CLLocationManager().authorizationStatus
        }
    }
    
    func requestLocationPermission() {
        // 这里只是检查，实际的权限请求在 LocationManager 中处理
        checkLocationPermission()
    }
    
    func checkSpeechRecognitionPermission() {
        DispatchQueue.main.async {
            self.speechRecognitionPermission = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechRecognitionPermission = status
            }
        }
    }
    
    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        var completedPermissions = 0
        let totalPermissions = 3
        
        let checkCompletion = {
            completedPermissions += 1
            if completedPermissions == totalPermissions {
                completion(self.allPermissionsGranted)
            }
        }
        
        // 请求麦克风权限
        if microphonePermission == .undetermined {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermission = self.convertToSessionPermission(granted)
                    checkCompletion()
                }
            }
        } else {
            checkCompletion()
        }
        
        // 请求位置权限
        if locationPermission == .notDetermined {
            // 位置权限请求在 LocationManager 中处理
            checkCompletion()
        } else {
            checkCompletion()
        }
        
        // 请求语音识别权限
        if speechRecognitionPermission == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.speechRecognitionPermission = status
                    checkCompletion()
                }
            }
        } else {
            checkCompletion()
        }
    }
    
    // MARK: - 跳转到系统设置
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { _ in
                // 设置页面关闭后重新检查权限
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkMicrophonePermission()
                    self.checkLocationPermission()
                    self.checkSpeechRecognitionPermission()
                }
            }
        }
    }
    
    // MARK: - 权限描述
    func getPermissionDescription(for permission: String) -> String {
        switch permission {
        case "麦克风":
            return "需要麦克风权限来录制语音和进行语音识别。请在设置中开启麦克风访问权限。"
        case "位置":
            return "需要定位权限来记录测试时的GPS坐标。请在设置中开启定位服务权限。"
        case "语音识别":
            return "需要语音识别权限来进行语音转文字功能。请在设置中开启语音识别权限。"
        default:
            return "未知权限"
        }
    }
} 
