//
//  AuthRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import Alamofire

enum AuthRouter {
    case refreshToken
}

extension AuthRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var headers: HTTPHeaders? {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]

        if case .refreshToken = self {
            if let refreshToken = try? KeychainManager.shared.loadRefreshToken() {
                headers["RefreshToken"] = refreshToken
            }
        }

        return headers
    }
}
