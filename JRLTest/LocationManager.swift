import Foundation
import CoreLocation

/**
 * LocationManager - GPS location tracking with centralized permission management
 * BEHAVIOR:
 * - Provides real-time GPS coordinate updates
 * - Handles location accuracy and distance filtering
 * - Tracks location status changes and errors
 * - Uses centralized PermissionManager for permission handling
 * EXCEPTIONS:
 * - Location permission denied by user
 * - GPS hardware failures
 * - Network connectivity issues affecting location services
 * DEPENDENCIES:
 * - Requires location permission (whenInUse or always)
 * - Requires GPS hardware access
 * - Uses CoreLocation framework
 * - Uses centralized PermissionManager
 */
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
        manager.distanceFilter = 1.0 // 1米精度
        
        // Initialize with current permission status from centralized manager
        DispatchQueue.main.async {
            self.authorizationStatus = self.permissionManager.locationPermission
            self.updateLocationStatus()
        }
    }
    
    /**
     * BEHAVIOR: Requests location permission using centralized PermissionManager
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: completion - Optional callback with permission result
     */
    func requestLocationPermission(completion: ((Bool) -> Void)? = nil) {
        print("LocationManager: Requesting location permission via PermissionManager")
        
        permissionManager.requestLocationPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("LocationManager: Permission granted, starting location updates")
                    self.startUpdatingLocation()
                } else {
                    print("LocationManager: Permission denied")
                    self.locationStatus = .denied
                }
                completion?(granted)
            }
        }
    }
    
    /**
     * BEHAVIOR: Starts continuous location updates
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func startUpdatingLocation() {
        print("LocationManager: Starting location updates")
        manager.startUpdatingLocation()
    }
    
    /**
     * BEHAVIOR: Stops continuous location updates
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
    func stopUpdatingLocation() {
        print("LocationManager: Stopping location updates")
        manager.stopUpdatingLocation()
    }
    
    /**
     * BEHAVIOR: Updates location status based on authorization and current location
     * EXCEPTIONS: None
     * RETURNS: None
     * PARAMETERS: None
     */
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
        print("LocationManager: Location status updated to: \(locationStatus)")
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
        
        print("LocationManager: Location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
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
        print("LocationManager: Location update failed: \(error.localizedDescription)")
        
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
        print("LocationManager: Authorization status changed: \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("LocationManager: Permission authorized, starting location updates")
                self.startUpdatingLocation()
            case .denied, .restricted:
                print("LocationManager: Permission denied or restricted")
                self.locationStatus = .denied
            case .notDetermined:
                print("LocationManager: Permission not determined")
                self.locationStatus = .unknown
            @unknown default:
                print("LocationManager: Unknown permission status")
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