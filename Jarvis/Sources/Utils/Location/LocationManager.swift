//
//  LocationManager.swift
//  Jarvis
//
//  Created by Ajaya Mati on 22/06/26.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private var authorizationStatus: CLAuthorizationStatus = .notDetermined

    init(updateCallback: (CLLocationCoordinate2D) -> Void) {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func initiate() {
        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        } else {
            startUpdatingLocation()
        }
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
            self.delegate?.didUpdateLocation(location: lastLocation.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
