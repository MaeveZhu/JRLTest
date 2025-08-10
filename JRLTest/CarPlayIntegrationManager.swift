import Foundation
import CarPlay
import SwiftUI
import CoreLocation

/**
 * CarPlayIntegrationManager - Manages integration between iOS app and CarPlay
 * BEHAVIOR:
 * - Coordinates communication between iOS app and CarPlay interface
 * - Manages state synchronization between interfaces
 * - Maps iOS app features to CarPlay-appropriate functionality
 * - Handles data flow and updates between interfaces
 * EXCEPTIONS: None
 * RETURNS: None
 * PARAMETERS: None
 * DEPENDENCIES:
 * - Requires Foundation framework
 * - Integrates with existing app managers
 * - Manages CarPlay interface updates
 */
@MainActor
class CarPlayIntegrationManager: NSObject, ObservableObject {
    static let shared = CarPlayIntegrationManager()
    
    @Published var isCarPlayConnected = false
    @Published var currentTestSession: TestSession?
    @Published var isRecording = false
    
    private var carPlayInterfaceController: CPInterfaceController?
    private var mainTemplate: CPTemplate?
    // Change from private to internal (remove private keyword)
    var locationManager = LocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        // Use the existing LocationManager's published properties
        // We'll observe location changes through the @Published currentLocation
    }
    
    func connectToCarPlay() {
        isCarPlayConnected = true
        print("🚗 CarPlay: Connected")
    }
    
    func disconnectFromCarPlay() {
        isCarPlayConnected = false
        print("🚗 CarPlay: Disconnected")
        
        // Clean up CarPlay interface
        carPlayInterfaceController = nil
        mainTemplate = nil
    }
    
    func updateCarPlayInterface() {
        print("🚗 CarPlay: Interface update requested")
        // This will be handled by CarPlaySceneDelegate
    }
    
    func updateCarPlayInterface(for testSession: TestSession) {
        currentTestSession = testSession
        print("🚗 CarPlay: Interface updated for test session")
    }
    
    func updateRecordingStatus(isRecording: Bool) {
        self.isRecording = isRecording
        print("🚗 CarPlay: Recording status updated: \(isRecording)")
    }
    
    func showRecordingStatus(isRecording: Bool) {
        self.isRecording = isRecording
        print("🚗 CarPlay: Showing recording status: \(isRecording)")
    }
    
    // MARK: - Location Handling
    
    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        if isRecording {
            print("🚗 CarPlay: Location update while recording: \(coordinate)")
            // Handle location update during recording
        }
    }
    
    // MARK: - Test Session Management
    
    func startTestSession(operatorCDSID: String, driverCDSID: String, testExecution: String, testProcedure: String, testType: String, testNumber: Int, startCoordinate: CLLocationCoordinate2D?) {
        let testSession = TestSession(
            operatorCDSID: operatorCDSID,
            driverCDSID: driverCDSID,
            testExecution: testExecution,
            testProcedure: testProcedure,
            testType: testType,
            testNumber: testNumber,
            startCoordinate: startCoordinate,
            startTime: Date()
        )
        
        currentTestSession = testSession
        print("🚗 CarPlay: Test session started")
    }
    
    func endTestSession() {
        guard var testSession = currentTestSession else { return }
        
        testSession.endTime = Date()
        currentTestSession = testSession
        print("🚗 CarPlay: Test session ended")
    }
    
    // MARK: - Recording Management
    
    func startRecording() {
        isRecording = true
        print("🚗 CarPlay: Recording started")
        
        // Start location updates using the existing LocationManager
        locationManager.startUpdatingLocation()
    }
    
    func stopRecording() {
        isRecording = false
        print("🚗 CarPlay: Recording stopped")
        
        // Stop location updates using the existing LocationManager
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CarPlay Interface Updates
    
    func getCurrentStatusItems() -> [CPListItem] {
        var items: [CPListItem] = []
        
        // Recording status
        let recordingStatus = CPListItem(
            text: "录音状态",
            detailText: isRecording ? "正在录音中..." : "未在录音",
            image: UIImage(systemName: isRecording ? "record.circle.fill" : "stop.circle.fill")
        )
        items.append(recordingStatus)
        
        // Test session status
        if let testSession = currentTestSession {
            let sessionStatus = CPListItem(
                text: "测试会话",
                detailText: "\(testSession.testProcedure) - \(testSession.testType)",
                image: UIImage(systemName: "car.fill")
            )
            items.append(sessionStatus)
        } else {
            let noSessionStatus = CPListItem(
                text: "测试会话",
                detailText: "无活动会话",
                image: UIImage(systemName: "car")
            )
            items.append(noSessionStatus)
        }
        
        // Location status
        let locationStatus = CPListItem(
            text: "位置状态",
            detailText: locationManager.locationStatus.description,
            image: UIImage(systemName: locationManager.currentLocation != nil ? "location.fill" : "location")
        )
        items.append(locationStatus)
        
        return items
    }
}

// MARK: - Supporting Types

enum CarPlayFeature {
    case startTest
    case recording
    case status
    case navigation
}

struct CarPlayTemplate {
    let template: CPTemplate
    let type: CarPlayFeature
}

protocol CarPlayInterface {
    func showMainInterface()
    func showTemplate(_ template: CarPlayTemplate)
    func showAlert(title: String, message: String, actions: [CPAlertAction])
}

// MARK: - LocationStatus Extension

extension LocationStatus {
    var description: String {
        switch self {
        case .unknown:
            return "未知"
        case .available:
            return "可用"
        case .denied:
            return "已拒绝"
        case .error(let message):
            return "错误: \(message)"
        }
    }
} 
