//
//  CommunityFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

final class CommunityFactory {
    static func create(postRepository: PostRepository, container: AppContainer) -> CommunityViewController {
        let presenter = CommunityPresenter(postRepository: postRepository)
        let viewController = CommunityViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
