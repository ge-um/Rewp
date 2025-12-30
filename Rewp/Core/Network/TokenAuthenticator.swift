//
//  TokenAuthenticator.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Alamofire

final class TokenAuthenticator: Authenticator {
    private let onRefreshSuccess: @Sendable (TokenCredential) -> Void
    private let onRefreshFailure: @Sendable () -> Void

    init(
        onRefreshSuccess: @escaping @Sendable (TokenCredential) -> Void,
        onRefreshFailure: @escaping @Sendable () -> Void
    ) {
        self.onRefreshSuccess = onRefreshSuccess
        self.onRefreshFailure = onRefreshFailure
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
        let bearerToken = "Bearer \(credential.accessToken)"
        return urlRequest.headers["Authorization"] == bearerToken
    }

    func refresh(
        _ credential: TokenCredential,
        for session: Session,
        completion: @escaping (Result<TokenCredential, Error>) -> Void
    ) {
        let url = "\(NetworkConfig.baseURL)/v1/auth/refresh"
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey,
            "RefreshToken": credential.refreshToken
        ]

        session.request(url, method: .get, headers: headers)
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

                    self.onRefreshSuccess(newCredential)
                    completion(.success(newCredential))

                case .failure(let error):
                    self.onRefreshFailure()
                    completion(.failure(error))
                }
            }
    }
}
