//  UserRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.

import Foundation
import Moya

enum UserRouter {
    case validateEmail(EmailValidationRequest)
    case join(JoinRequest)
    case login(LoginRequest)
}

extension UserRouter: TargetType {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .validateEmail:
            return "/v1/users/validation/email"
        case .join:
            return "/v1/users/join"
        case .login:
            return "/v1/users/login"
        }
    }

    var method: Moya.Method {
        return .post
    }

    var task: Task {
        switch self {
        case .validateEmail(let request):
            return .requestJSONEncodable(request)
        case .join(let request):
            return .requestJSONEncodable(request)
        case .login(let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }
}
