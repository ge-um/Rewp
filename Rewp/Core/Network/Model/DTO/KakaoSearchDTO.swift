//
//  KakaoSearchDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

struct KakaoSearchResponse: Decodable {
    let documents: [KakaoPlaceDTO]
}

struct KakaoPlaceDTO: Decodable {
    let placeName: String
    let addressName: String
    let roadAddressName: String
    let x: String
    let y: String
    let categoryName: String

    enum CodingKeys: String, CodingKey {
        case placeName = "place_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x
        case y
        case categoryName = "category_name"
    }
}
