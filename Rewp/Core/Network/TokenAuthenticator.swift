//
//  TokenAuthenticator.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Alamofire

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
        return response.statusCode == 419 || response.statusCode == 401
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
        let refreshSession = Session()

        refreshSession.request(AuthRouter.refreshToken)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: RefreshTokenResponse.self) { [weak self] response in
                guard let self = self else {
                    completion(.failure(AuthError.unknown))
                    return
                }

                switch response.result {
                case .success(let refreshResponse):
                    guard let newCredential = TokenCredential.from(
                        accessToken: refreshResponse.accessToken,
                        refreshToken: refreshResponse.refreshToken
                    ) else {
                        completion(.failure(AuthError.invalidToken))
                        return
                    }

                    try? self.keychainManager.saveAccessToken(newCredential.accessToken)
                    try? self.keychainManager.saveRefreshToken(newCredential.refreshToken)
                    completion(.success(newCredential))

                case .failure(let error):
                    try? self.keychainManager.deleteAllTokens()
                    NotificationCenter.default.post(name: .authenticationFailed, object: nil)
                    completion(.failure(error))
                }
            }
    }
}
