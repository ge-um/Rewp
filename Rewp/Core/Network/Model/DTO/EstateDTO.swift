//
//  EstateDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import RxSwift

struct LikeEstateRequest: Codable {
    let like_status: Bool
}

struct LikeEstateResponse: Codable {
    let like_status: Bool
}

struct Geolocation: Codable {
    let longitude: Double
    let latitude: Double
}

struct TodayEstatesResponse: Codable {
    let data: [EstateDTO]
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

struct EstateOptions: Codable {
    let option1: String?
    let option2: String?
    let option3: String?
    let option4: String?
    let option5: String?
    let option6: String?
    let option7: String?
    let option8: String?
    let option9: String?
    let option10: String?

    var allOptions: [String] {
        [option1, option2, option3, option4, option5, option6, option7, option8, option9, option10]
            .compactMap { $0 }
    }
}

struct EstateCreator: Codable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
    let phoneNum: String?
}

struct EstateComment: Codable {
    let comment_id: String
    let content: String
    let created_at: String
    let creator: EstateCreator
    let replies: [EstateComment]?
}

struct EstateDetailResponse: Codable {
    let estate_id: String
    let category: String
    let title: String
    let introduction: String
    let reservation_price: Int
    let description: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let maintenance_fee: Int
    let area: Double
    let parking_count: Int
    let floors: Int
    let options: EstateOptions
    let geolocation: Geolocation
    let creator: EstateCreator
    let like_count: Int
    let is_liked: Bool
    let is_reserved: Bool
    let is_safe_estate: Bool
    let is_recommended: Bool
    let comments: [EstateComment]?
    let created_at: String
    let updated_at: String
}

extension EstateDetailResponse {
    func toEstateDetail() -> EstateDetail {
        let imageURLs = thumbnails.map { "\(NetworkConfig.baseURL)\($0)" }

        let depositInManwon = deposit / 10000
        let rentInManwon = monthly_rent / 10000
        let priceType: String
        let price: String

        if monthly_rent == 0 {
            priceType = "전세"
            price = "\(depositInManwon.formatted())"
        } else {
            priceType = "월세"
            price = "\(depositInManwon.formatted())/\(rentInManwon.formatted())"
        }

        let maintenanceFeeInManwon = maintenance_fee / 10000
        let managementFeeText = "관리비 \(maintenanceFeeInManwon)만원 • \(area)m²"

        let parkingInfo = parking_count > 0 ? "세대별 차량 \(parking_count)대 주차 가능" : "주차 불가"

        let creatorProfileImageURL = creator.profileImage.map { "\(NetworkConfig.baseURL)\($0)" }

        let relativeTime = updated_at.toRelativeTimeString()

        return EstateDetail(
            estateId: estate_id,
            title: title,
            imageURLs: imageURLs,
            isSafeEstate: is_safe_estate,
            isLiked: is_liked,
            isReserved: is_reserved,
            reservationPrice: reservation_price,
            category: category,
            priceType: priceType,
            price: price,
            managementFeeText: managementFeeText,
            options: options.allOptions,
            parkingInfo: parkingInfo,
            description: description,
            creatorId: creator.user_id,
            creatorName: creator.nick,
            creatorIntroduction: creator.introduction ?? "",
            creatorProfileImageURL: creatorProfileImageURL,
            creatorPhoneNumber: creator.phoneNum,
            relativeTime: relativeTime
        )
    }
}

extension EstateDTO: ClusterPoint {
    var latitude: Double {
        return geolocation.latitude
    }

    var longitude: Double {
        return geolocation.longitude
    }
}

extension EstateDTO {
    func toSimilarEstateItem() -> SimilarEstateItem {
        let depositInManwon = deposit / 10000
        let rentInManwon = monthly_rent / 10000

        let priceText: String
        if monthly_rent == 0 {
            priceText = "전세 \(depositInManwon.formatted())만"
        } else {
            priceText = "월세 \(depositInManwon.formatted())/\(rentInManwon.formatted())"
        }

        let areaText = "\(category) \(area)m²"
        let recommendText = is_recommended ? "추천" : nil
        let imageURL = thumbnails.first.map { "\(NetworkConfig.baseURL)\($0)" }

        return SimilarEstateItem(
            estateId: estate_id,
            recommend: recommendText,
            category: category,
            price: priceText,
            area: areaText,
            imageURL: imageURL
        )
    }

    func toBannerItem() -> Single<BannerItem> {
        return GeocodeService.shared
            .reverseGeocode(
                latitude: geolocation.latitude,
                longitude: geolocation.longitude
            )
            .map { [self] location in
                BannerItem(
                    id: estate_id,
                    imageURL: thumbnails.first.map { "\(NetworkConfig.baseURL)\($0)" },
                    location: location,
                    title: title,
                    description: introduction
                )
            }
            .catch { [self] _ in
                .just(BannerItem(
                    id: estate_id,
                    imageURL: thumbnails.first.map { "\(NetworkConfig.baseURL)\($0)" },
                    location: category,
                    title: title,
                    description: introduction
                ))
            }
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
