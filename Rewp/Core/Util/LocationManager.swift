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
        updateAuthorizationStatus()
    }

    func requestWhenInUseAuthorization() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocationForInitial()
        }
    }

    func checkAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    func isAuthorized() -> Bool {
        let status = checkAuthorizationStatus()
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

    private func updateAuthorizationStatus() {
        authorizationStatusRelay.accept(locationManager.authorizationStatus)
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
        updateAuthorizationStatus()

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        Logger.location.notice("Authorization status changed - \(String(describing: status), privacy: .public)")

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocationForInitial()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusRelay.accept(status)

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocationForInitial()
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
