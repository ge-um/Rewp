//
//  TokenAuthenticator.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Alamofire
import OSLog

final class TokenAuthenticator: Authenticator {
    private let keychainManager: KeychainManager

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    func apply(_ credential: TokenCredential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(credential.accessToken))
    }

    func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: Error
    ) -> Bool {
        if urlRequest.url?.path.contains("/auth/refresh") == true {
            Logger.auth.error("Refresh token failed - clearing auth state")
            return false
        }

        let shouldRetry = response.statusCode == 419 || response.statusCode == 401
        Logger.auth.warning("Authentication failed [\(response.statusCode)] - \(urlRequest.url?.path ?? "unknown", privacy: .public)")
        return shouldRetry
    }

    func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: TokenCredential
    ) -> Bool {
        return urlRequest.headers["Authorization"] == credential.accessToken
    }

    func refresh(
        _ credential: TokenCredential,
        for session: Session,
        completion: @escaping (Result<TokenCredential, Error>) -> Void
    ) {
        Logger.auth.notice("Refreshing expired token")

        session.request(AuthRouter.refreshToken)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: RefreshTokenResponse.self) { [weak self] response in
                guard let self = self else {
                    Logger.auth.error("Authenticator deallocated during refresh")
                    completion(.failure(AuthError.unknown))
                    return
                }

                switch response.result {
                case .success(let refreshResponse):
                    guard let newCredential = TokenCredential.from(
                        accessToken: refreshResponse.accessToken,
                        refreshToken: refreshResponse.refreshToken
                    ) else {
                        Logger.auth.error("Invalid token format in refresh response")
                        completion(.failure(AuthError.invalidToken))
                        return
                    }

                    try? self.keychainManager.saveAccessToken(refreshResponse.accessToken)
                    try? self.keychainManager.saveRefreshToken(refreshResponse.refreshToken)
                    Logger.auth.notice("Token refreshed successfully")

                    completion(.success(newCredential))

                case .failure(let error):
                    Logger.auth.error("Token refresh failed - \(error.localizedDescription)")

                    try? self.keychainManager.deleteAllTokens()
                    NotificationCenter.default.post(name: .authenticationFailed, object: nil)
                    completion(.failure(error))
                }
            }
    }
}
