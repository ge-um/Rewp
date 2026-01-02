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
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }
}
