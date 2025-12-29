//
//  AuthRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import Moya

enum AuthRouter {
    case refreshToken
}

extension AuthRouter: TargetType {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .refreshToken:
            return "/v1/auth/refresh"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        var headers = [
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
