//
//  ChatRoomFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit

final class ChatRoomFactory {
    static func create(roomId: String, roomTitle: String, container: AppContainer) -> ChatRoomViewController {
        let presenter = ChatRoomPresenter(roomId: roomId, roomTitle: roomTitle)
        let viewController = ChatRoomViewController()

        viewController.presenter = presenter

        return viewController
    }
}
