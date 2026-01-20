//
//  Sido.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import MapKit

struct Sido {
    let code: String
    let name: String
    let nameEn: String
    let center: CLLocationCoordinate2D
    let boundingBox: (minLon: Double, minLat: Double, maxLon: Double, maxLat: Double)
    let polygon: MKPolygon

    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MKMapPoint(coordinate)
        let renderer = MKPolygonRenderer(polygon: polygon)
        let mapPoint = renderer.point(for: point)
        return renderer.path?.contains(mapPoint) ?? false
    }
}
