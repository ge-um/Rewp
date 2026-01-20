//
//  MapSearchFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation

final class MapSearchFactory {
    static func create(estateRepository: EstateRepository, container: AppContainer) -> MapSearchViewController {
        let clusteringEngine = ClusteringEngine<EstateDTO>(minZoom: 11)
        let presenter = MapSearchPresenter(
            estateRepository: estateRepository,
            clusteringEngine: clusteringEngine
        )
        let viewController = MapSearchViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
