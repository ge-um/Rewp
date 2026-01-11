//
//  RecentlyViewedEstateItem.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

struct RecentlyViewedEstateItem: Codable {
    let estateId: String
    let recommend: String?
    let category: String
    let priceType: String
    let price: String
    let area: String
    let imageURL: String?
    let viewedAt: Date
}
