//
//  HomeFactory.swift
//  Rewp
//
//  Created by 금가경 on 12/19/25.
//

import UIKit

class HomeFactory {
    static func create(container: AppContainer) -> HomeViewController {
        let presenter = HomePresenter()
        let viewController = HomeViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
