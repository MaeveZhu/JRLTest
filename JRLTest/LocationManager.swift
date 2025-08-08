import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let permissionManager = PermissionManager.shared
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationStatus: LocationStatus = .unknown
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1.0
        
        DispatchQueue.main.async {
            self.authorizationStatus = self.permissionManager.locationPermission
            self.updateLocationStatus()
        }
    }
    
    func requestLocationPermission(completion: ((Bool) -> Void)? = nil) {
        permissionManager.requestLocationPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.startUpdatingLocation()
                } else {
                    self.locationStatus = .denied
                }
                completion?(granted)
            }
        }
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
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
    }
    
    // MARK: - CLLocationManagerDelegate
    
    /**
     * BEHAVIOR: Handles location updates from CoreLocation
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: 
     * - manager: CLLocationManager instance
     * - locations: Array of CLLocation objects
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.updateLocationStatus()
        }
    }
    
    /**
     * BEHAVIOR: Handles location errors from CoreLocation
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS:
     * - manager: CLLocationManager instance
     * - error: Location error details
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationStatus = .error(error.localizedDescription)
        }
    }
    
    /**
     * BEHAVIOR: Handles authorization status changes and syncs with PermissionManager
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS:
     * - manager: CLLocationManager instance
     * - status: New authorization status
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.locationStatus = .denied
            case .notDetermined:
                self.locationStatus = .unknown
            @unknown default:
                self.locationStatus = .unknown
            }
        }
    }
}

/**
 * LocationStatus - Enumeration of possible location service states
 * BEHAVIOR: Represents the current state of location services
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 */
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