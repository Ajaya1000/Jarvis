//
//  LocationManager.swift
//  Jarvis
//
//  Created by Ajaya Mati on 22/06/26.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case notAuthorised
    case unknown
}

fileprivate class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var didUpdateLocation: ((CLLocationCoordinate2D) -> Void)?

    init(didUpdateLocation: ((CLLocationCoordinate2D) -> Void)?) throws(LocationError) {
        super.init()
        self.didUpdateLocation = didUpdateLocation
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        try initiate()
    }
    
    private func initiate() throws(LocationError) {
        switch manager.authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .restricted, .denied:
            throw .notAuthorised
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            throw .unknown
        }
    }
    
    func tearDown() {
        stopUpdatingLocation()
    }
    
    private func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    private func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    private func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Grab the most recent location update
        if let lastLocation = locations.last {
            didUpdateLocation?(lastLocation.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

class LocationUtil {
    // need to hold location manager otherwise it would get deinitalized
    private var locationManager: LocationManager?
    
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    self.locationManager =  try LocationManager { [weak self] location in
                        self?.locationManager?.tearDown()
                        self?.locationManager = nil
                        continuation.resume(returning: location)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
