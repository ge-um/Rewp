//
//  AuthService.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import RxSwift
import Alamofire

extension Notification.Name {
    static let authenticationFailed = Notification.Name("authenticationFailed")
}

protocol AuthServiceProtocol {
    func login(accessToken: String, refreshToken: String) throws
    func logout() -> Single<Void>
    func isAuthenticated() -> Bool
    func authenticatedRequest<T: Decodable>(_ router: APIRouter) -> Single<T>
    func authenticatedRequestEmpty(_ router: APIRouter) -> Single<Void>
    func refreshSession()
}

final class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let keychainManager: KeychainManager
    private var session: Session
    private let authenticator: TokenAuthenticator

    private var currentCredential: TokenCredential? {
        guard let accessToken = try? keychainManager.loadAccessToken(),
              let refreshToken = try? keychainManager.loadRefreshToken() else {
            return nil
        }

        return TokenCredential.from(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }

    init(networkService: NetworkServiceProtocol, keychainManager: KeychainManager = .shared) {
        self.networkService = networkService
        self.keychainManager = keychainManager
        self.authenticator = TokenAuthenticator(keychainManager: keychainManager)

        if let accessToken = try? keychainManager.loadAccessToken(),
           let refreshToken = try? keychainManager.loadRefreshToken(),
           let credential = TokenCredential.from(
               accessToken: accessToken,
               refreshToken: refreshToken
           ) {
            let interceptor = AuthenticationInterceptor(
                authenticator: authenticator,
                credential: credential
            )
            self.session = Session(interceptor: interceptor)
        } else {
            self.session = Session()
        }
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

        refreshSession()
    }

    func logout() -> Single<Void> {
        return authenticatedRequestEmpty(UserRouter.logout)
            .catch { _ in .just(()) }
            .do(onSuccess: { [weak self] _ in
                self?.clearAuthState()
                self?.refreshSession()
            })
    }

    func isAuthenticated() -> Bool {
        return currentCredential != nil
    }

    func authenticatedRequest<T: Decodable>(_ router: APIRouter) -> Single<T> {
        guard currentCredential != nil else {
            return .error(AuthError.notAuthenticated)
        }

        return Single.create { observer in
            let dataRequest = self.session.request(router)
                .responseDecodable(of: T.self) { response in
                    if let statusCode = response.response?.statusCode {
                        if (200...299).contains(statusCode) {
                            switch response.result {
                            case .success(let value):
                                observer(.success(value))
                            case .failure:
                                observer(.failure(NetworkError.decodingError))
                            }
                        } else {
                            if let data = response.data,
                               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                            } else {
                                observer(.failure(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다.")))
                            }
                        }
                    } else {
                        observer(.failure(NetworkError.serverError(message: "서버 응답을 받지 못했습니다.")))
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
                .response { response in
                    if let statusCode = response.response?.statusCode {
                        if (200...299).contains(statusCode) {
                            observer(.success(()))
                        } else {
                            if let data = response.data,
                               let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                observer(.failure(NetworkError.serverError(message: errorResponse.message)))
                            } else {
                                observer(.failure(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다.")))
                            }
                        }
                    } else {
                        observer(.failure(NetworkError.serverError(message: "서버 응답을 받지 못했습니다.")))
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

    func refreshSession() {
        guard let credential = currentCredential else {
            return
        }

        let interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: credential
        )

        self.session = Session(interceptor: interceptor)
    }

    private func clearAuthState() {
        try? keychainManager.deleteAllTokens()
        NotificationCenter.default.post(
            name: .authenticationFailed,
            object: nil
        )
    }
}
