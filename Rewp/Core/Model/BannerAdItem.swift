//
//  BannerAdItem.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation

struct BannerAdItem {
    let name: String
    let imageURL: String
    let payloadType: String
    let payloadValue: String
}

extension BannerAdItem {
    func toNewsAdItem() -> (title: String, description: String, payloadType: String, payloadValue: String) {
        return (
            title: "출석 이벤트",
            description: "매일 출석하고 혜택 받기",
            payloadType: self.payloadType,
            payloadValue: self.payloadValue
        )
    }
}
