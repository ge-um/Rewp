//
//  EstateOptionMapper.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation

struct EstateOptionMapper {
    static let optionIconMap: [String: String] = [
        "냉장고": "Refrigerator",
        "세탁기": "WashingMachine",
        "에어컨": "AirConditioner",
        "전자레인지": "Microwave",
        "싱크대": "Sink",
        "TV": "Television",
        "신발장": "ShoeCabinet",
        "옷장": "Closet"
    ]

    static func filterAndMap(options: [String]) -> [(name: String, icon: String)] {
        return options
            .filter { !$0.hasPrefix("기타") }
            .compactMap { optionName in
                guard let iconName = optionIconMap[optionName] else { return nil }
                return (name: optionName, icon: iconName)
            }
    }
}
