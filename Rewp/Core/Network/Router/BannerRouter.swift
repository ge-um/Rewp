//
//  BannerRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import Alamofire

enum BannerRouter {
    case mainBanners
}

extension BannerRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .mainBanners:
            return "/banners/main"
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
