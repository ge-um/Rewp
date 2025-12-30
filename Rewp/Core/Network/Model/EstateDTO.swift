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
            imageURL: thumbnails.first.map { "\(NetworkConfig.baseURL)/v1\($0)" },
            location: category,
            title: title,
            description: introduction
        )
    }
}
