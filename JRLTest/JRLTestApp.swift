//
//  JRLTestApp.swift
//  JRLTest
//
//  Created by whosyihan on 7/25/25.
//

import SwiftUI

@main
struct JRLTestApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    
    init() {
        // Set up crash prevention
        setupCrashPrevention()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Handle app becoming active
                    handleAppBecameActive()
                }
        }
    }
    
    private func setupCrashPrevention() {
        // Set up global exception handling
        NSSetUncaughtExceptionHandler { exception in
            print("Uncaught exception: \(exception)")
            print("Stack trace: \(exception.callStackSymbols)")
        }
        
        // Set up signal handling for abort signals
        signal(SIGABRT) { signal in
            print("Received SIGABRT signal: \(signal)")
        }
        
        signal(SIGSEGV) { signal in
            print("Received SIGSEGV signal: \(signal)")
        }
    }
    
    private func handleAppBecameActive() {
        // Re-check permissions when app becomes active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            permissionManager.checkLocationPermission()
        }
    }
}
