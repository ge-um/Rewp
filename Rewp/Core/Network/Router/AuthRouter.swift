//
//  AuthRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import Alamofire
import OSLog

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

        do {
            let accessToken = try KeychainManager.shared.loadAccessToken()
            let refreshToken = try KeychainManager.shared.loadRefreshToken()
            
            headers["Authorization"] = accessToken
            headers["RefreshToken"] = refreshToken
            
            Logger.auth.debug("accessToken: \(accessToken, privacy: .public), refreshToken: \(refreshToken, privacy: .public)")
        } catch {
            Logger.auth.error("Failed to load tokens for request header - \(error.localizedDescription)")
        }

        return headers
    }
}
