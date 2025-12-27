//
//  UserRepository.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation
import RxSwift

protocol UserRepository {
    func validateEmail(_ email: String) -> Single<EmailValidationResponse>
    func join(_ request: JoinRequest) -> Single<JoinResponse>
    func login(email: String, password: String) -> Single<LoginResponse>
    func appleLogin(idToken: String, deviceToken: String) -> Single<AppleLoginResponse>
}

final class UserRepositoryImpl: UserRepository {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func validateEmail(_ email: String) -> Single<EmailValidationResponse> {
        let request = EmailValidationRequest(email: email)
        return networkService.request(UserRouter.validateEmail(request))
    }

    func join(_ request: JoinRequest) -> Single<JoinResponse> {
        return networkService.request(UserRouter.join(request))
    }

    func login(email: String, password: String) -> Single<LoginResponse> {
        let deviceToken = "temp-device-token"
        let request = LoginRequest(
            email: email,
            password: password,
            deviceToken: deviceToken
        )
        return networkService.request(UserRouter.login(request))
    }

    func appleLogin(idToken: String, deviceToken: String) -> Single<AppleLoginResponse> {
        let request = AppleLoginRequest(
            idToken: idToken,
            deviceToken: deviceToken
        )
        return networkService.request(UserRouter.appleLogin(request))
    }
}
