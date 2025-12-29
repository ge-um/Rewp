//
//  AppContainer.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation

final class AppContainer {
    // MARK: - Shared Dependencies

    lazy var networkService: NetworkServiceProtocol = {
        return NetworkService()
    }()

    lazy var authService: AuthServiceProtocol = {
        return AuthService(networkService: networkService)
    }()

    lazy var userRepository: UserRepository = {
        UserRepositoryImpl(networkService: networkService)
    }()

    lazy var logRepository: LogRepository = {
        LogRepositoryImpl(networkService: networkService)
    }()

    // MARK: - Factory Methods

    func makeLoginViewController() -> LoginViewController {
        return LoginFactory.create(container: self)
    }

    func makeSignUpViewController() -> SignUpViewController {
        return SignUpFactory.create(container: self)
    }

    func makeHomeViewController() -> HomeViewController {
        return HomeFactory.create(container: self)
    }

    func makeSettingsViewController() -> SettingsViewController {
        return SettingsFactory.create(container: self)
    }
}
