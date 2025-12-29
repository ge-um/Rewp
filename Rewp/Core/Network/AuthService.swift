//
//  AuthService.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Moya
import RxSwift

extension Notification.Name {
    static let authenticationFailed = Notification.Name("authenticationFailed")
}

protocol AuthServiceProtocol {
    func login(accessToken: String, refreshToken: String) throws
    func logout() -> Single<Void>
    func isAuthenticated() -> Bool
    func getValidAccessToken() -> Single<String>
    func authenticatedRequest<T: Decodable>(_ target: TargetType) -> Single<T>
    func authenticatedRequestEmpty(_ target: TargetType) -> Single<Void>
}

final class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let keychainManager: KeychainManager
    private var currentCredential: TokenCredential?
    private var refreshTokenSubject: Single<TokenCredential>?

    init(networkService: NetworkServiceProtocol, keychainManager: KeychainManager = .shared) {
        self.networkService = networkService
        self.keychainManager = keychainManager
        self.currentCredential = loadCredentialFromKeychain()
    }

    func login(accessToken: String, refreshToken: String) throws {
        guard let credential = TokenCredential.from(
            accessToken: accessToken,
            refreshToken: refreshToken
        ) else {
            throw AuthError.invalidToken
        }

        try keychainManager.saveAccessToken(accessToken)
        try keychainManager.saveRefreshToken(refreshToken)
        self.currentCredential = credential
    }

    func logout() -> Single<Void> {
        guard let credential = currentCredential else {
            clearAuthState()
            return .just(())
        }

        let authenticatedTarget = AuthenticatedTarget(
            base: UserRouter.logout,
            accessToken: credential.accessToken
        )

        return networkService.requestEmpty(authenticatedTarget)
            .catch { _ in .just(()) }
            .do(onSuccess: { [weak self] _ in
                self?.clearAuthState()
            })
    }

    func isAuthenticated() -> Bool {
        return currentCredential != nil
    }

    func getValidAccessToken() -> Single<String> {
        guard let credential = currentCredential else {
            return .error(AuthError.notAuthenticated)
        }

        if credential.requiresRefresh {
            return refreshTokenIfNeeded()
                .map { $0.accessToken }
        }

        return .just(credential.accessToken)
    }

    func authenticatedRequest<T: Decodable>(_ target: TargetType) -> Single<T> {
        return getValidAccessToken()
            .flatMap { [weak self] accessToken -> Single<T> in
                guard let self = self else {
                    return .error(AuthError.unknown)
                }
                let authenticatedTarget = AuthenticatedTarget(
                    base: target,
                    accessToken: accessToken
                )
                return self.networkService.request(authenticatedTarget)
                    .catch { error -> Single<T> in
                        if case AuthError.tokenExpired = error {
                            return self.refreshTokenIfNeeded()
                                .flatMap { credential in
                                    let retryTarget = AuthenticatedTarget(
                                        base: target,
                                        accessToken: credential.accessToken
                                    )
                                    return self.networkService.request(retryTarget)
                                }
                        } else if case AuthError.notAuthenticated = error {
                            self.clearAuthState()
                            return .error(error)
                        } else {
                            return .error(error)
                        }
                    }
            }
    }

    func authenticatedRequestEmpty(_ target: TargetType) -> Single<Void> {
        return getValidAccessToken()
            .flatMap { [weak self] accessToken -> Single<Void> in
                guard let self = self else {
                    return .error(AuthError.unknown)
                }
                let authenticatedTarget = AuthenticatedTarget(
                    base: target,
                    accessToken: accessToken
                )
                return self.networkService.requestEmpty(authenticatedTarget)
                    .catch { error -> Single<Void> in
                        if case AuthError.tokenExpired = error {
                            return self.refreshTokenIfNeeded()
                                .flatMap { credential in
                                    let retryTarget = AuthenticatedTarget(
                                        base: target,
                                        accessToken: credential.accessToken
                                    )
                                    return self.networkService.requestEmpty(retryTarget)
                                }
                        } else if case AuthError.notAuthenticated = error {
                            self.clearAuthState()
                            return .error(error)
                        } else {
                            return .error(error)
                        }
                    }
            }
    }

    private func loadCredentialFromKeychain() -> TokenCredential? {
        guard let accessToken = try? keychainManager.loadAccessToken(),
              let refreshToken = try? keychainManager.loadRefreshToken() else {
            return nil
        }

        return TokenCredential.from(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }

    private func clearAuthState() {
        try? keychainManager.deleteAllTokens()
        currentCredential = nil
        NotificationCenter.default.post(
            name: .authenticationFailed,
            object: nil
        )
    }

    private func refreshTokenIfNeeded() -> Single<TokenCredential> {
        if let existing = refreshTokenSubject {
            return existing
        }

        let request: Single<TokenCredential> = networkService.request(AuthRouter.refreshToken)
            .flatMap { [weak self] (response: RefreshTokenResponse) -> Single<TokenCredential> in
                guard let self = self else {
                    return .error(AuthError.unknown)
                }

                guard let credential = TokenCredential.from(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                ) else {
                    self.clearAuthState()
                    return .error(AuthError.invalidToken)
                }

                try? self.keychainManager.saveAccessToken(response.accessToken)
                try? self.keychainManager.saveRefreshToken(response.refreshToken)
                self.currentCredential = credential

                return .just(credential)
            }
            .catch { [weak self] error in
                self?.clearAuthState()
                return .error(AuthError.refreshFailed)
            }

        let sharedRequest = request
            .do(onDispose: { [weak self] in
                self?.refreshTokenSubject = nil
            })

        refreshTokenSubject = sharedRequest
        return sharedRequest
    }
}
