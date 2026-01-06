//
//  Notification+Names.swift
//  Rewp
//
//  Created by 금가경 on 01/05/26.
//

import Foundation

extension Notification.Name {
    static let chatMessageReceived = Notification.Name("chatMessageReceived")
    static let currentChatRoomChanged = Notification.Name("currentChatRoomChanged")
    static let chatListNeedsRefresh = Notification.Name("chatListNeedsRefresh")
}

struct ChatMessageReceivedInfo {
    let roomId: String
}

struct CurrentChatRoomInfo {
    let roomId: String?
}
