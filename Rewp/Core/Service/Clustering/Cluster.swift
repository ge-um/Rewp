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
    let expansionZoom: Int?
    let actualCount: Int

    var count: Int {
        return actualCount
    }

    init(id: String, latitude: Double, longitude: Double, points: [T], expansionZoom: Int? = nil, actualCount: Int? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.points = points
        self.expansionZoom = expansionZoom
        self.actualCount = actualCount ?? points.count
    }
}

enum ClusterResult<T: ClusterPoint> {
    case single(T)
    case cluster(Cluster<T>)

    var coordinate: (latitude: Double, longitude: Double) {
        switch self {
        case .single(let point):
            return (point.latitude, point.longitude)
        case .cluster(let cluster):
            return (cluster.latitude, cluster.longitude)
        }
    }
}
