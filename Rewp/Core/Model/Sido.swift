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

    var shortName: String {
        if name.hasSuffix("특별시") || name.hasSuffix("광역시") {
            return String(name.dropLast(3))
        } else if name.hasSuffix("특별자치시") {
            return String(name.dropLast(5))
        } else if name.hasSuffix("특별자치도") {
            let prefix = String(name.dropLast(5))
            switch prefix {
            case "제주":
                return "제주도"
            case "전북":
                return "전라북도"
            default:
                return prefix
            }
        }
        return name
    }

    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MKMapPoint(coordinate)
        let renderer = MKPolygonRenderer(polygon: polygon)
        let mapPoint = renderer.point(for: point)
        return renderer.path?.contains(mapPoint) ?? false
    }
}
