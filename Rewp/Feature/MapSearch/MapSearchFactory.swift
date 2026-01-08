//
//  MapSearchFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation

final class MapSearchFactory {
    static func create(estateRepository: EstateRepository) -> MapSearchViewController {
        let presenter = MapSearchPresenter(estateRepository: estateRepository)
        let viewController = MapSearchViewController()

        viewController.presenter = presenter

        return viewController
    }
}
