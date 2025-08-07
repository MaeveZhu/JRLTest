//
//  SharedModels.swift
//  JRLTest Siri Extension
//
//  Created by whosyihan on 8/4/25.
//

import Foundation
import CoreLocation

// Simple data structure for Siri Extension
struct SiriTestSession {
    let vin: String
    let testExecutionId: String
    let tag: String
    let startCoordinate: CLLocationCoordinate2D?
    let startTime: Date
    
    init(vin: String, testExecutionId: String, tag: String, startCoordinate: CLLocationCoordinate2D?, startTime: Date) {
        self.vin = vin
        self.testExecutionId = testExecutionId
        self.tag = tag
        self.startCoordinate = startCoordinate
        self.startTime = startTime
    }
} 