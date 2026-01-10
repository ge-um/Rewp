//
//  Cluster.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation

struct Cluster<T: ClusterPoint> {
    let id: String
    let latitude: Double
    let longitude: Double
    let points: [T]
    let actualCount: Int
    var amenityInfo: AmenityInfo?

    var count: Int {
        return actualCount
    }

    init(id: String, latitude: Double, longitude: Double, points: [T], actualCount: Int? = nil, amenityInfo: AmenityInfo? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.points = points
        self.actualCount = actualCount ?? points.count
        self.amenityInfo = amenityInfo
    }

    func radiusInMeters(zoom: Int, radius: Int, extent: Int) -> Double {
        let earthCircumference: Double = 40075017.0
        let metersPerPixel = (earthCircumference * cos(latitude * .pi / 180.0)) / (pow(2.0, Double(zoom)) * Double(extent))
        let calculatedRadius = Double(radius) * metersPerPixel
        return min(calculatedRadius, 20000.0)
    }
}
