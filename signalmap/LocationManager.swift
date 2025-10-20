//
//  LocationManager.swift
//  blist
//
//  Created by Brian Greeson on 10/14/25.
//

import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class LocationManager: NSObject, ObservableObject, @MainActor CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorized = false
    @Published var location: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        location = manager.location
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        authorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if authorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Use the most recent location
        if let latest = locations.last {
            assert(Thread.isMainThread)
            self.location = latest
        }
    }
}

