//
//  EstateDetailModel.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation

struct EstateDetail {
    let estateId: String
    let title: String
    let imageURLs: [String]
    let isSafeEstate: Bool
    let isLiked: Bool
    let isReserved: Bool
    let reservationPrice: Int
    let category: String
    let priceType: String
    let price: String
    let managementFeeText: String
    let options: [String]
    let parkingInfo: String
    let description: String
    let creatorName: String
    let creatorIntroduction: String
    let creatorProfileImageURL: String?
    let creatorPhoneNumber: String?
    let relativeTime: String
}
