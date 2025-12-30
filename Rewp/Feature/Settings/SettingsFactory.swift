//
//  SettingsFactory.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit

final class SettingsFactory {
    static func create(container: AppContainer) -> SettingsViewController {
        let presenter = SettingsPresenter(authService: container.authService)
        let viewController = SettingsViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
