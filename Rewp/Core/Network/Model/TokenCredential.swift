//
//  TokenCredential.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import Alamofire

struct TokenCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiration: Date

    var requiresRefresh: Bool {
        Date(timeIntervalSinceNow: 60) > expiration
    }

    static func from(accessToken: String, refreshToken: String) -> TokenCredential? {
        guard let expiration = JWTDecoder.extractExpiration(from: accessToken) else {
            return nil
        }

        return TokenCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: expiration
        )
    }
}
