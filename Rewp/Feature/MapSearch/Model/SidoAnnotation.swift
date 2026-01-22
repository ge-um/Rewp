//
//  SidoAnnotation.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import MapKit

final class SidoAnnotation: NSObject, MKAnnotation {
    let sido: Sido
    let estateCount: Int

    var coordinate: CLLocationCoordinate2D {
        return sido.center
    }

    var title: String? {
        return sido.name
    }

    init(sido: Sido, estateCount: Int) {
        self.sido = sido
        self.estateCount = estateCount
        super.init()
    }
}
