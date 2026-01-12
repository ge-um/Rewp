//
//  EstateAnnotation.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateAnnotation: NSObject, MKAnnotation {
    let estate: EstateDTO
    var coordinate: CLLocationCoordinate2D

    init(estate: EstateDTO) {
        self.estate = estate
        self.coordinate = CLLocationCoordinate2D(
            latitude: estate.geolocation.latitude,
            longitude: estate.geolocation.longitude
        )
        super.init()
    }
}

