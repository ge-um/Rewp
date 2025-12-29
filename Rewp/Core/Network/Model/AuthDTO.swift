//
//  AuthDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
