//
//  FeedFactory.swift
//  Rewp
//
//  Created by 금가경 on 12/19/25.
//

import UIKit

class FeedFactory {
    static func create(container: AppContainer) -> FeedViewController {
        let presenter = FeedPresenter(estateRepository: container.estateRepository)
        let viewController = FeedViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
