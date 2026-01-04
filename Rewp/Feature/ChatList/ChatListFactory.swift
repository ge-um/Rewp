//
//  ChatListFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit

final class ChatListFactory {
    static func create(container: AppContainer) -> ChatListViewController {
        let presenter = ChatListPresenter(
            repository: container.chatRepository,
            authService: container.authService
        )
        let viewController = ChatListViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
