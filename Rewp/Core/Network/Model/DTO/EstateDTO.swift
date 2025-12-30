//
//  EstateDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation

struct Geolocation: Codable {
    let longitude: Double
    let latitude: Double
}

struct EstateDTO: Codable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let area: Double
    let floors: Int
    let geolocation: Geolocation
    let distance: Double?
    let like_count: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let created_at: String
    let updated_at: String
}

struct TodayEstatesResponse: Codable {
    let data: [EstateDTO]
}

extension EstateDTO {
    func toBannerItem() -> BannerItem {
        return BannerItem(
            id: estate_id,
            imageURL: thumbnails.first.map { "\(NetworkConfig.baseURL)\($0)" },
            location: category,
            title: title,
            description: introduction
        )
    }

    func toHotEstateItem() -> HotEstateItem {
        let depositInManwon = deposit / 10000
        let rentInManwon = monthly_rent / 10000

        let priceText: String
        if monthly_rent == 0 {
            priceText = "전세 \(depositInManwon.formatted())만"
        } else {
            priceText = "월세 \(depositInManwon.formatted())/\(rentInManwon.formatted())"
        }

        let infoText = "면적 \(area)m²"

        return HotEstateItem(
            id: estate_id,
            imageURL: thumbnails.first.map { "\(NetworkConfig.baseURL)\($0)" },
            title: title,
            price: priceText,
            info: infoText
        )
    }
}
