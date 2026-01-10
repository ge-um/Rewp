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

    var count: Int {
        return actualCount
    }

    init(id: String, latitude: Double, longitude: Double, points: [T], actualCount: Int? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.points = points
        self.actualCount = actualCount ?? points.count
    }
}
