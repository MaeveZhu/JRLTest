import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationStatus: LocationStatus = .unknown
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1.0 // 1米精度
        
        // 初始化时检查当前权限状态
        DispatchQueue.main.async {
            self.authorizationStatus = self.manager.authorizationStatus
            self.updateLocationStatus()
        }
    }
    
    func requestLocationPermission() {
        print("LocationManager: 请求位置权限")
        let currentStatus = manager.authorizationStatus
        print("LocationManager: 当前权限状态: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            print("LocationManager: 权限未确定，请求权限")
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: 权限已授权，开始更新位置")
            startUpdatingLocation()
        case .denied, .restricted:
            print("LocationManager: 权限被拒绝或受限")
            DispatchQueue.main.async {
                self.locationStatus = .denied
            }
        @unknown default:
            print("LocationManager: 未知权限状态")
            DispatchQueue.main.async {
                self.locationStatus = .unknown
            }
        }
    }
    
    func startUpdatingLocation() {
        print("LocationManager: 开始更新位置")
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("LocationManager: 停止更新位置")
        manager.stopUpdatingLocation()
    }
    
    private func updateLocationStatus() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if currentLocation != nil {
                locationStatus = .available
            } else {
                locationStatus = .unknown
            }
        case .denied, .restricted:
            locationStatus = .denied
        case .notDetermined:
            locationStatus = .unknown
        @unknown default:
            locationStatus = .unknown
        }
        print("LocationManager: 位置状态更新为: \(locationStatus)")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("LocationManager: 位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.updateLocationStatus()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: 位置更新失败: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.locationStatus = .error(error.localizedDescription)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LocationManager: 权限状态改变: \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("LocationManager: 权限已授权，开始更新位置")
                self.startUpdatingLocation()
            case .denied, .restricted:
                print("LocationManager: 权限被拒绝或受限")
                self.locationStatus = .denied
            case .notDetermined:
                print("LocationManager: 权限未确定")
                self.locationStatus = .unknown
            @unknown default:
                print("LocationManager: 未知权限状态")
                self.locationStatus = .unknown
            }
        }
    }
}

enum LocationStatus: Equatable {
    case unknown
    case available
    case denied
    case error(String)
    
    static func == (lhs: LocationStatus, rhs: LocationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.available, .available):
            return true
        case (.denied, .denied):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
} 