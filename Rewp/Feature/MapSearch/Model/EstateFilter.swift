//
//  EstateFilter.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation

struct EstateFilter {
    var areaRange: (min: Int, max: Int)?
    var depositRange: (min: Int, max: Int)?
    var rentRange: (min: Int, max: Int)?

    var isActive: Bool {
        return areaRange != nil || depositRange != nil || rentRange != nil
    }

    func matches(_ estate: EstateDTO) -> Bool {
        if let areaRange = areaRange {
            let areaInPyeong = estate.area / 3.3058
            if areaInPyeong < Double(areaRange.min) || areaInPyeong > Double(areaRange.max) {
                return false
            }
        }

        if let depositRange = depositRange {
            let depositInManwon = estate.deposit / 10000
            if depositInManwon < depositRange.min || depositInManwon > depositRange.max {
                return false
            }
        }

        if let rentRange = rentRange {
            let rentInManwon = estate.monthly_rent / 10000
            if rentInManwon < rentRange.min || rentInManwon > rentRange.max {
                return false
            }
        }

        return true
    }
}
