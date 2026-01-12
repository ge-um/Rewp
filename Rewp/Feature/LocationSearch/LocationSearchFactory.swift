//
//  LocationSearchFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import Foundation

final class LocationSearchFactory {
    static func create() -> LocationSearchViewController {
        let presenter = LocationSearchPresenter()
        let viewController = LocationSearchViewController()

        viewController.presenter = presenter

        return viewController
    }
}
