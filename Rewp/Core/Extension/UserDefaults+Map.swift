//
//  UserDefaults+Map.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import CoreLocation

extension UserDefaults {
    private enum Keys {
        static let lastMapCenterLat = "lastMapCenterLat"
        static let lastMapCenterLon = "lastMapCenterLon"
    }

    var lastMapCenter: CLLocationCoordinate2D? {
        get {
            guard object(forKey: Keys.lastMapCenterLat) != nil else { return nil }
            let lat = double(forKey: Keys.lastMapCenterLat)
            let lon = double(forKey: Keys.lastMapCenterLon)
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            if let coord = newValue {
                set(coord.latitude, forKey: Keys.lastMapCenterLat)
                set(coord.longitude, forKey: Keys.lastMapCenterLon)
            } else {
                removeObject(forKey: Keys.lastMapCenterLat)
                removeObject(forKey: Keys.lastMapCenterLon)
            }
        }
    }
}
