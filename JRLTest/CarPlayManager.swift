import Foundation
import SwiftUI

@MainActor
class CarPlayManager: ObservableObject {
    static let shared = CarPlayManager()
    
    @Published var isCarPlayConnected = false
    @Published var isRecording = false
    @Published var currentTestSession: TestSession?
    
    private init() {}
    
    func connectToCarPlay() {
        isCarPlayConnected = true
        print("�� CarPlay: Connected")
    }
    
    func disconnectFromCarPlay() {
        isCarPlayConnected = false
        print("🚗 CarPlay: Disconnected")
    }
    
    func updateCarPlayInterface() {
        print("�� CarPlay: Interface updated")
    }
    
    func updateCarPlayInterface(for testSession: TestSession) {
        currentTestSession = testSession
        print("�� CarPlay: Interface updated for test session")
    }
    
    func updateRecordingStatus(isRecording: Bool) {
        self.isRecording = isRecording
        print("�� CarPlay: Recording status updated: \(isRecording)")
    }
    
    func showRecordingStatus(isRecording: Bool) {
        self.isRecording = isRecording
        print("🚗 CarPlay: Showing recording status: \(isRecording)")
    }
} 