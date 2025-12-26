//  AppContainer.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.

import Foundation

final class AppContainer {
    // MARK: - Shared Dependencies

    lazy var networkService: NetworkServiceProtocol = {
        return NetworkService()
    }()

    lazy var userRepository: UserRepository = {
        return UserRepositoryImpl(networkService: networkService)
    }()

    // MARK: - Factory Methods

    func makeHomeViewController() -> HomeViewController {
        let presenter = HomePresenter()
        let viewController = HomeViewController()
        viewController.presenter = presenter
        viewController.userRepository = userRepository
        return viewController
    }
}
