//
//  EstateClusterAnnotation.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateClusterAnnotation: MKClusterAnnotation {
    var count: Int {
        return memberAnnotations.count
    }

    var estates: [EstateDTO] {
        return memberAnnotations.compactMap { ($0 as? EstateAnnotation)?.estate }
    }
}
