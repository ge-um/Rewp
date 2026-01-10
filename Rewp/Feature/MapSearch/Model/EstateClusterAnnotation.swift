//
//  EstateClusterAnnotation.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateClusterAnnotation: NSObject, MKAnnotation {
    let cluster: Cluster<EstateDTO>
    var coordinate: CLLocationCoordinate2D

    var count: Int {
        return cluster.count
    }

    var amenityInfo: AmenityInfo? {
        return cluster.amenityInfo
    }

    init(cluster: Cluster<EstateDTO>) {
        self.cluster = cluster
        self.coordinate = CLLocationCoordinate2D(
            latitude: cluster.latitude,
            longitude: cluster.longitude
        )
        super.init()
    }
}
