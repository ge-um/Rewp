//
//  BannerDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation

struct BannerPayload: Codable {
    let type: String
    let value: String
}

struct BannerDTO: Codable {
    let name: String
    let imageUrl: String
    let payload: BannerPayload
}

struct MainBannersResponse: Codable {
    let data: [BannerDTO]
}

extension BannerDTO {
    func toBannerAdItem() -> BannerAdItem {
        return BannerAdItem(
            name: name,
            imageURL: imageUrl,
            payloadType: payload.type,
            payloadValue: payload.value
        )
    }
}
