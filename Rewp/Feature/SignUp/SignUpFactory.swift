//
//  SignUpFactory.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation

final class SignUpFactory {
    static func create(container: AppContainer) -> SignUpViewController {
        let presenter = SignUpPresenter(userRepository: container.userRepository)
        let viewController = SignUpViewController()

        viewController.presenter = presenter

        return viewController
    }
}
