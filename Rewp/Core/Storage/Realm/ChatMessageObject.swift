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

    @Persisted var isSent: Bool = true
    @Persisted var tempId: String?

    convenience init(
        chatId: String,
        roomId: String,
        content: String,
        senderId: String,
        senderNickname: String,
        senderProfileImage: String?,
        createdAt: Date,
        isFromMe: Bool,
        isSent: Bool = true,
        tempId: String? = nil
    ) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProfileImage = senderProfileImage
        self.createdAt = createdAt
        self.isFromMe = isFromMe
        self.isSent = isSent
        self.tempId = tempId
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
            isFromMe: isFromMe
        )
    }

    static func fromDomain(
        _ message: ChatMessage,
        isSent: Bool = true,
        tempId: String? = nil
    ) -> ChatMessageObject {
        return ChatMessageObject(
            chatId: message.chatId,
            roomId: message.roomId,
            content: message.content,
            senderId: message.senderId,
            senderNickname: message.senderNickname,
            senderProfileImage: message.senderProfileImage,
            createdAt: message.createdAt,
            isFromMe: message.isFromMe,
            isSent: isSent,
            tempId: tempId
        )
    }
}
