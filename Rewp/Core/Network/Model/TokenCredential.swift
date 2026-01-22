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

    var requiresRefresh: Bool {
        return false
    }

    init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
