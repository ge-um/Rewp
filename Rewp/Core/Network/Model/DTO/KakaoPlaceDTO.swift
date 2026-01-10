//
//  KakaoPlaceDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation

struct KakaoPlaceResponse: Codable {
    let meta: Meta
    let documents: [PlaceDocument]

    struct Meta: Codable {
        let total_count: Int
        let pageable_count: Int
        let is_end: Bool
    }

    struct PlaceDocument: Codable {
        let place_name: String
        let id: String
        let x: String
        let y: String
    }
}
