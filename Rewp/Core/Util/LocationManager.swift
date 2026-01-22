//
//  LocationManager.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import Foundation
import CoreLocation
import OSLog
import RxSwift
import RxCocoa

final class LocationManager: NSObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private let currentLocationRelay = PublishRelay<CLLocation>()
    private let authorizationStatusRelay = BehaviorRelay<CLAuthorizationStatus>(value: .notDetermined)
    private var isRequestingInitialLocation = false

    var currentLocation: Observable<CLLocation> {
        return currentLocationRelay.asObservable()
    }

    var authorizationStatus: Observable<CLAuthorizationStatus> {
        return authorizationStatusRelay.asObservable()
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func checkAuthorizationStatus() -> CLAuthorizationStatus {
        return authorizationStatusRelay.value
    }

    func isAuthorized() -> Bool {
        let status = authorizationStatusRelay.value
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func requestCurrentLocation() {
        Logger.location.notice("Requesting current location")
        startUpdatingLocationForInitial()
    }

    private func startUpdatingLocationForInitial() {
        isRequestingInitialLocation = true
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Logger.location.debug("Location updated - latitude: \(location.coordinate.latitude, privacy: .public), longitude: \(location.coordinate.longitude, privacy: .public)")

        currentLocationRelay.accept(location)

        if isRequestingInitialLocation {
            isRequestingInitialLocation = false
            locationManager.stopUpdatingLocation()
            Logger.location.notice("Initial location acquired, stopped updating")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.location.error("Location update failed - \(error.localizedDescription)")

        if isRequestingInitialLocation {
            isRequestingInitialLocation = false
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        self.authorizationStatusRelay.accept(status)
        Logger.location.notice("Authorization status changed - \(String(describing: status), privacy: .public)")
        
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            self.startUpdatingLocationForInitial()
        default:
            break
        }
    }
}

extension LocationManager {
    static let defaultCoordinate = CLLocationCoordinate2D(
        latitude: 37.5176577,
        longitude: 126.8864088
    )
    static let defaultAddress = "문래동"
}
