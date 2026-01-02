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
}
