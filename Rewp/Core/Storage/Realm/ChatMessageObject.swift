//
//  ChatMessageObject.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import RealmSwift

final class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var senderId: String
    @Persisted var senderNickname: String
    @Persisted var senderProfileImage: String?
    @Persisted var createdAt: Date
    @Persisted var isFromMe: Bool

    @Persisted var sendStatusRaw: String = SendStatus.sent.rawValue
    @Persisted var tempId: String?

    var sendStatus: SendStatus {
        get { SendStatus(rawValue: sendStatusRaw) ?? .sent }
        set { sendStatusRaw = newValue.rawValue }
    }
}

extension ChatMessageObject {
    func toDomain() -> ChatMessage {
        return ChatMessage(
            chatId: chatId,
            roomId: roomId,
            content: content,
            senderId: senderId,
            senderNickname: senderNickname,
            senderProfileImage: senderProfileImage,
            createdAt: createdAt,
            isFromMe: isFromMe,
            sendStatus: sendStatus,
            tempId: tempId
        )
    }

    static func fromDomain(
        _ message: ChatMessage,
        sendStatus: SendStatus? = nil,
        tempId: String? = nil
    ) -> ChatMessageObject {
        let object = ChatMessageObject()
        object.chatId = message.chatId
        object.roomId = message.roomId
        object.content = message.content
        object.senderId = message.senderId
        object.senderNickname = message.senderNickname
        object.senderProfileImage = message.senderProfileImage
        object.createdAt = message.createdAt
        object.isFromMe = message.isFromMe
        object.sendStatus = sendStatus ?? message.sendStatus
        object.tempId = tempId ?? message.tempId
        return object
    }
}
