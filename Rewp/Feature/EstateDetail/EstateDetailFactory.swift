//
//  EstateDetailFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation

final class EstateDetailFactory {
    static func create(
        estateId: String,
        container: AppContainer
    ) -> EstateDetailViewController {
        let presenter = EstateDetailPresenter(estateId: estateId)
        let viewController = EstateDetailViewController(estateId: estateId)

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
