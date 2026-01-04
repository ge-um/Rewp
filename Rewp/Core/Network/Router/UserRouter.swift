//
//  UserRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation
import Alamofire

enum UserRouter {
    case validateEmail(EmailValidationRequest)
    case join(JoinRequest)
    case login(LoginRequest)
    case appleLogin(AppleLoginRequest)
    case kakaoLogin(KakaoLoginRequest)
    case logout
    case updateDeviceToken(DeviceTokenRequest)
}

extension UserRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .validateEmail:
            return "/users/validation/email"
        case .join:
            return "/users/join"
        case .login:
            return "/users/login"
        case .appleLogin:
            return "/users/login/apple"
        case .kakaoLogin:
            return "/users/login/kakao"
        case .logout:
            return "/users/logout"
        case .updateDeviceToken:
            return "/users/deviceToken"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .updateDeviceToken:
            return .put
        default:
            return .post
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
        case .validateEmail(let request):
            return request
        case .join(let request):
            return request
        case .login(let request):
            return request
        case .appleLogin(let request):
            return request
        case .kakaoLogin(let request):
            return request
        case .logout:
            return nil
        case .updateDeviceToken(let request):
            return request
        }
    }
}
