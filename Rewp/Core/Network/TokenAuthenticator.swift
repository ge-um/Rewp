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
    private let refreshSession = Session()

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    func apply(_ credential: TokenCredential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(credential.accessToken))
    }
    
    func refresh(
        _ credential: TokenCredential,
        for session: Session,
        completion: @escaping (Result<TokenCredential, Error>) -> Void
    ) {
        Logger.auth.notice("Refreshing expired token")

        refreshSession.request(AuthRouter.refreshToken)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: RefreshTokenResponse.self) { [weak self] response in
                guard let self = self else {
                    Logger.auth.error("Authenticator deallocated during refresh")
                    completion(.failure(AuthError.unknown))
                    return
                }

                switch response.result {
                case .success(let refreshResponse):
                    let newCredential = TokenCredential(
                        accessToken: refreshResponse.accessToken,
                        refreshToken: refreshResponse.refreshToken
                    )

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

    func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: Error
    ) -> Bool {
        return response.statusCode == 419
    }

    func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: TokenCredential
    ) -> Bool {
        return urlRequest.headers["Authorization"] == credential.accessToken
    }
}
