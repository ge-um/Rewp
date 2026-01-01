//
//  TokenCredential.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import Alamofire
import OSLog

struct TokenCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiration: Date

    var requiresRefresh: Bool {
        let fiveMinutesBeforeExpiration = expiration.addingTimeInterval(-300)
        let needsRefresh = Date() > fiveMinutesBeforeExpiration
        if needsRefresh {
            Logger.token.notice("Token expiring soon - \(self.expiration, privacy: .public)")
        }
        return needsRefresh
    }

    static func from(accessToken: String, refreshToken: String) -> TokenCredential? {
        guard let expiration = JWTDecoder.extractExpiration(from: accessToken) else {
            Logger.token.error("Failed to extract expiration from token")
            return nil
        }

        return TokenCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: expiration
        )
    }
}
