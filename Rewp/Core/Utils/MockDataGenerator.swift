//
//  MockDataGenerator.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import Foundation

enum MockDataGenerator {
    static func generateEstates(count: Int) -> [EstateDTO] {
        (0..<count).map { index in
            EstateDTO(
                estate_id: "mock_\(index)",
                category: "원룸",
                title: "테스트 매물 \(index)",
                introduction: "테스트 설명",
                thumbnails: [],
                deposit: Int.random(in: 1000000...100000000),
                monthly_rent: Int.random(in: 100000...2000000),
                built_year: "2020",
                area: Double.random(in: 10...50),
                floors: 5,
                geolocation: Geolocation(
                    longitude: Double.random(in: 125.0...132.0),
                    latitude: Double.random(in: 33.0...38.0)
                ),
                distance: nil,
                like_count: 0,
                is_safe_estate: false,
                is_recommended: false,
                created_at: "2026-01-01",
                updated_at: "2026-01-01"
            )
        }
    }
}
