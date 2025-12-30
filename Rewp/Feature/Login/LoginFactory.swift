//
//  LoginFactory.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit

final class LoginFactory {
    static func create(container: AppContainer) -> LoginViewController {
        let presenter = LoginPresenter(userRepository: container.userRepository, container: container)
        let viewController = LoginViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
