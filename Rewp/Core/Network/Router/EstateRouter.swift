//
//  EstateRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import Alamofire

enum EstateRouter {
    case todayEstates
    case hotEstates
    case todayTopic
    case estateDetail(estateId: String)
    case similarEstates
    case likeEstate(estateId: String, likeStatus: Bool)
    case geolocationEstates(longitude: Double?, latitude: Double?, maxDistance: Double?, category: String?)
}

extension EstateRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .todayEstates:
            return "/estates/today-estates"
        case .hotEstates:
            return "/estates/hot-estates"
        case .todayTopic:
            return "/estates/today-topic"
        case .estateDetail(let estateId):
            return "/estates/\(estateId)"
        case .similarEstates:
            return "/estates/similar-estates"
        case .likeEstate(let estateId, _):
            return "/estates/\(estateId)/like"
        case .geolocationEstates:
            return "/estates/geolocation"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .likeEstate:
            return .post
        default:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }

    var body: Encodable? {
        switch self {
        case .likeEstate(_, let likeStatus):
            return LikeEstateRequest(like_status: likeStatus)
        default:
            return nil
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .geolocationEstates(let longitude, let latitude, let maxDistance, let category):
            var params: [String: String] = [:]
            if let longitude = longitude {
                params["longitude"] = String(longitude)
            }
            if let latitude = latitude {
                params["latitude"] = String(latitude)
            }
            if let maxDistance = maxDistance {
                params["maxDistance"] = String(maxDistance)
            }
            if let category = category {
                params["category"] = category
            }
            return params.isEmpty ? nil : params
        default:
            return nil
        }
    }
}
