//
//  AmenityInfo.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation

struct AmenityInfo {
    let parks: Int
    let mountains: Int
    let rivers: Int
    let veterinary: Int
    let cafes: Int
    let playgrounds: Int

    var total: Int {
        return parks + mountains + rivers + veterinary + cafes + playgrounds
    }

    var isEmpty: Bool {
        return total == 0
    }

    func displayText() -> String {
        var components: [String] = []
        if parks > 0 {
            components.append("공원\(parks)")
        }
        if mountains > 0 {
            components.append("산\(mountains)")
        }
        if rivers > 0 {
            components.append("강\(rivers)")
        }
        if veterinary > 0 {
            components.append("동물병원\(veterinary)")
        }
        if cafes > 0 {
            components.append("애견카페\(cafes)")
        }
        if playgrounds > 0 {
            components.append("애견운동장\(playgrounds)")
        }
        return components.joined(separator: " ")
    }
}
