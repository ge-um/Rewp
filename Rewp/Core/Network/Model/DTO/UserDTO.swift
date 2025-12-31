//
//  UserDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation

struct EmailValidationRequest: Codable {
    let email: String
}

struct EmailValidationResponse: Codable {
    let message: String
}

struct JoinRequest: Codable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String
    let introduction: String?
    let deviceToken: String
}

struct JoinResponse: Codable {
    let user_id: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceToken: String
}

struct LoginResponse: Codable {
    let user_id: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}

struct AppleLoginRequest: Codable {
    let idToken: String
    let deviceToken: String
}

struct AppleLoginResponse: Codable {
    let user_id: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}

struct KakaoLoginRequest: Codable {
    let oauthToken: String
    let deviceToken: String
}

struct KakaoLoginResponse: Codable {
    let user_id: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}

struct ErrorResponse: Codable {
    let message: String
}
