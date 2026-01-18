//
//  ChatRoomObject.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import RealmSwift

final class ChatRoomObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var participantId: String
    @Persisted var participantName: String
    @Persisted var participantProfileImage: String?
    @Persisted var lastMessage: String
    @Persisted var lastMessageDate: Date
    @Persisted var unreadCount: Int
    @Persisted var lastReadAt: Date?
    @Persisted var updatedAt: Date?
    @Persisted var messages: List<ChatMessageObject>

    convenience init(
        roomId: String,
        participantId: String,
        participantName: String,
        participantProfileImage: String?,
        lastMessage: String,
        lastMessageDate: Date,
        unreadCount: Int,
        lastReadAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.init()
        self.roomId = roomId
        self.participantId = participantId
        self.participantName = participantName
        self.participantProfileImage = participantProfileImage
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.lastReadAt = lastReadAt
        self.updatedAt = updatedAt
    }
}

extension ChatRoomObject {
    func toDomain() -> ChatRoom {
        return ChatRoom(
            roomId: roomId,
            participantId: participantId,
            participantName: participantName,
            participantProfileImage: participantProfileImage,
            lastMessage: lastMessage,
            lastMessageDate: lastMessageDate,
            unreadCount: unreadCount,
            updatedAt: updatedAt
        )
    }

    static func fromDomain(_ chatRoom: ChatRoom) -> ChatRoomObject {
        return ChatRoomObject(
            roomId: chatRoom.roomId,
            participantId: chatRoom.participantId,
            participantName: chatRoom.participantName,
            participantProfileImage: chatRoom.participantProfileImage,
            lastMessage: chatRoom.lastMessage,
            lastMessageDate: chatRoom.lastMessageDate,
            unreadCount: chatRoom.unreadCount,
            lastReadAt: nil,
            updatedAt: chatRoom.updatedAt
        )
    }
}
