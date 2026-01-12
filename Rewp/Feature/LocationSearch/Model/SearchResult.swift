//
//  SearchResult.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import Foundation
import CoreLocation

enum LocationType {
    case address
    case subway
    case university
}

struct SearchResult {
    let address: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
}
