//
//  AuthService.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Moya
import RxSwift
import Alamofire

extension Notification.Name {
    static let authenticationFailed = Notification.Name("authenticationFailed")
}

protocol AuthServiceProtocol {
    func login(accessToken: String, refreshToken: String) throws
    func logout() -> Single<Void>
    func isAuthenticated() -> Bool
    func authenticatedRequest<T: Decodable>(_ target: TargetType) -> Single<T>
    func authenticatedRequestEmpty(_ target: TargetType) -> Single<Void>
}

final class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let keychainManager: KeychainManager
    private let authenticatedProvider: MoyaProvider<MultiTarget>

    init(networkService: NetworkServiceProtocol, keychainManager: KeychainManager = .shared) {
        self.networkService = networkService
        self.keychainManager = keychainManager

        let credential = Self.loadCredential(from: keychainManager)

        let authenticator = TokenAuthenticator(
            onRefreshSuccess: { credential in
                try? keychainManager.saveAccessToken(credential.accessToken)
                try? keychainManager.saveRefreshToken(credential.refreshToken)
            },
            onRefreshFailure: {
                try? keychainManager.deleteAllTokens()
                NotificationCenter.default.post(
                    name: .authenticationFailed,
                    object: nil
                )
            }
        )

        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: credential
        )

        let session = Session(interceptor: interceptor)
        self.authenticatedProvider = MoyaProvider<MultiTarget>(session: session)
    }

    func login(accessToken: String, refreshToken: String) throws {
        guard TokenCredential.from(
            accessToken: accessToken,
            refreshToken: refreshToken
        ) != nil else {
            throw AuthError.invalidToken
        }

        try keychainManager.saveAccessToken(accessToken)
        try keychainManager.saveRefreshToken(refreshToken)
    }

    func logout() -> Single<Void> {
        return authenticatedRequestEmpty(UserRouter.logout)
            .catch { _ in .just(()) }
            .do(onSuccess: { [weak self] _ in
                self?.clearAuthState()
            })
    }

    func isAuthenticated() -> Bool {
        return Self.loadCredential(from: keychainManager) != nil
    }

    func authenticatedRequest<T: Decodable>(_ target: TargetType) -> Single<T> {
        guard Self.loadCredential(from: keychainManager) != nil else {
            return .error(AuthError.notAuthenticated)
        }

        return authenticatedProvider.rx.request(MultiTarget(target))
            .flatMap { response -> Single<T> in
                if (200...299).contains(response.statusCode) {
                    do {
                        let data = try response.map(T.self)
                        return .just(data)
                    } catch {
                        return .error(NetworkError.decodingError)
                    }
                } else {
                    if let errorResponse = try? response.map(ErrorResponse.self) {
                        return .error(NetworkError.serverError(message: errorResponse.message))
                    } else {
                        return .error(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다."))
                    }
                }
            }
            .catch { [weak self] error in
                if case AuthError.notAuthenticated = error {
                    self?.clearAuthState()
                }
                return .error(error)
            }
    }

    func authenticatedRequestEmpty(_ target: TargetType) -> Single<Void> {
        guard Self.loadCredential(from: keychainManager) != nil else {
            return .error(AuthError.notAuthenticated)
        }

        return authenticatedProvider.rx.request(MultiTarget(target))
            .flatMap { response -> Single<Void> in
                if (200...299).contains(response.statusCode) {
                    return .just(())
                } else {
                    if let errorResponse = try? response.map(ErrorResponse.self) {
                        return .error(NetworkError.serverError(message: errorResponse.message))
                    } else {
                        return .error(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다."))
                    }
                }
            }
            .catch { [weak self] error in
                if case AuthError.notAuthenticated = error {
                    self?.clearAuthState()
                }
                return .error(error)
            }
    }

    private static func loadCredential(from keychainManager: KeychainManager) -> TokenCredential? {
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
        NotificationCenter.default.post(
            name: .authenticationFailed,
            object: nil
        )
    }
}
