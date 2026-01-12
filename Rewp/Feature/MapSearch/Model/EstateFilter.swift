//
//  EstateFilter.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation
import OSLog

struct EstateFilter {
    var areaRange: (min: Int, max: Int)?
    var depositRange: (min: Int, max: Int)?
    var rentRange: (min: Int, max: Int)?

    var isActive: Bool {
        return areaRange != nil || depositRange != nil || rentRange != nil
    }

    func matches(_ estate: EstateDTO) -> Bool {
        if let areaRange = areaRange {
            let minAreaInM2 = Double(areaRange.min) * 3.3058
            let maxAreaInM2 = Double(areaRange.max) * 3.3058
            if estate.area < minAreaInM2 || estate.area > maxAreaInM2 {
                return false
            }
        }

        if let depositRange = depositRange {
            let depositInManwon = estate.deposit / 10000
            let passed = depositInManwon >= depositRange.min && depositInManwon <= depositRange.max
            if !passed {
                Logger.mapFilter.debug("보증금 필터 제외 - deposit: \(estate.deposit, privacy: .public) (\(depositInManwon, privacy: .public)만원), range: \(depositRange.min, privacy: .public)~\(depositRange.max, privacy: .public)")
            }
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
