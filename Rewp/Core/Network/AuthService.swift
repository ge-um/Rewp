//
//  AuthService.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import RxSwift
import Alamofire
import OSLog

extension Notification.Name {
    static let authenticationFailed = Notification.Name("authenticationFailed")
}

protocol AuthServiceProtocol {
    func login(accessToken: String, refreshToken: String) throws
    func logout() -> Single<Void>
    func isAuthenticated() -> Bool
    func authenticatedRequest<T: Decodable>(_ router: APIRouter) -> Single<T>
    func authenticatedRequestEmpty(_ router: APIRouter) -> Single<Void>
}

final class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let keychainManager: KeychainManager
    private let authenticator: TokenAuthenticator
    private var session: Session

    private var currentCredential: TokenCredential? {
        do {
            let accessToken = try keychainManager.loadAccessToken()
            let refreshToken = try keychainManager.loadRefreshToken()
            return TokenCredential.from(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        } catch {
            Logger.auth.error("Failed to load tokens from keychain - \(error.localizedDescription)")
            return nil
        }
    }

    init(networkService: NetworkServiceProtocol, keychainManager: KeychainManager = .shared) {
        self.networkService = networkService
        self.keychainManager = keychainManager
        self.authenticator = TokenAuthenticator(keychainManager: keychainManager)

        let credential: TokenCredential?
        do {
            let accessToken = try keychainManager.loadAccessToken()
            let refreshToken = try keychainManager.loadRefreshToken()
            credential = TokenCredential.from(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        } catch {
            Logger.auth.error("Failed to load tokens during AuthService init - \(error.localizedDescription)")
            credential = nil
        }

        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: credential
        )
        self.session = Session(interceptor: interceptor)
    }

    func login(accessToken: String, refreshToken: String) throws {
        guard let credential = TokenCredential.from(
            accessToken: accessToken,
            refreshToken: refreshToken
        ) else {
            Logger.auth.error("Invalid token format during login")
            throw AuthError.invalidToken
        }

        try keychainManager.saveAccessToken(accessToken)
        try keychainManager.saveRefreshToken(refreshToken)

        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: credential
        )
        self.session = Session(interceptor: interceptor)
        Logger.auth.notice("User logged in")
    }

    func logout() -> Single<Void> {
        return authenticatedRequestEmpty(UserRouter.logout)
            .catch { _ in .just(()) }
            .do(onSuccess: { [weak self] _ in
                self?.clearAuthState()
            })
    }

    func isAuthenticated() -> Bool {
        return currentCredential != nil
    }

    func authenticatedRequest<T: Decodable>(_ router: APIRouter) -> Single<T> {
        guard currentCredential != nil else {
            Logger.auth.error("No credential available")
            return .error(AuthError.notAuthenticated)
        }

        Logger.network.notice("Making authenticated request - \(router.path)")

        return Single.create { observer in
            let dataRequest = self.session.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        Logger.network.notice("Request succeeded - \(router.path)")
                        observer(.success(value))
                    case .failure:
                        let statusCode = response.response?.statusCode ?? 0

                        if let data = response.data {
                            if let jsonString = String(data: data, encoding: .utf8) {
                                Logger.network.error("Response JSON - \(jsonString)")
                            }

                            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                Logger.network.error("Request failed [\(statusCode)] - \(errorResponse.message)")
                                observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                            } else {
                                Logger.network.error("Request failed [\(statusCode)] - decoding error")
                                observer(.failure(NetworkError.decodingError))
                            }
                        } else {
                            Logger.network.error("Request failed [\(statusCode)] - no data")
                            observer(.failure(NetworkError.decodingError))
                        }
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
        .catch { [weak self] error in
            if case AuthError.notAuthenticated = error {
                self?.clearAuthState()
            }
            return .error(error)
        }
    }

    func authenticatedRequestEmpty(_ router: APIRouter) -> Single<Void> {
        guard currentCredential != nil else {
            return .error(AuthError.notAuthenticated)
        }

        return Single.create { observer in
            let dataRequest = self.session.request(router)
                .validate(statusCode: 200..<300)
                .response { response in
                    switch response.result {
                    case .success:
                        observer(.success(()))
                    case .failure:
                        if let data = response.data,
                           let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                        } else {
                            observer(.failure(NetworkError.serverError(message: "서버 오류가 발생했습니다.")))
                        }
                    }
                }

            return Disposables.create {
                dataRequest.cancel()
            }
        }
        .catch { [weak self] error in
            if case AuthError.notAuthenticated = error {
                self?.clearAuthState()
            }
            return .error(error)
        }
    }

    private func clearAuthState() {
        do {
            try keychainManager.deleteAllTokens()
        } catch {
            Logger.auth.error("Failed to delete tokens during clearAuthState - \(error.localizedDescription)")
        }

        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: nil
        )
        self.session = Session(interceptor: interceptor)

        NotificationCenter.default.post(
            name: .authenticationFailed,
            object: nil
        )
        Logger.auth.notice("Authentication state cleared")
    }
}
