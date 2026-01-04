//
//  ChatMessage.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation

enum SendStatus: String {
    case sending = "sending"
    case failed = "failed"
    case sent = "sent"
}

struct ChatMessage {
    let chatId: String
    let roomId: String
    let content: String
    let senderId: String
    let senderNickname: String
    let senderProfileImage: String?
    let createdAt: Date
    let isFromMe: Bool
    let sendStatus: SendStatus
    let tempId: String?

    init(
        chatId: String,
        roomId: String,
        content: String,
        senderId: String,
        senderNickname: String,
        senderProfileImage: String?,
        createdAt: Date,
        isFromMe: Bool,
        sendStatus: SendStatus = .sent,
        tempId: String? = nil
    ) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProfileImage = senderProfileImage
        self.createdAt = createdAt
        self.isFromMe = isFromMe
        self.sendStatus = sendStatus
        self.tempId = tempId
    }
}

extension ChatMessage {
    static func mockMessages(roomId: String) -> [ChatMessage] {
        let now = Date()
        let calendar = Calendar.current

        return [
            ChatMessage(
                chatId: "1",
                roomId: roomId,
                content: "안녕하세요! 매물 문의드립니다.",
                senderId: "other-user",
                senderNickname: "김부동산",
                senderProfileImage: nil,
                createdAt: calendar.date(byAdding: .minute, value: -30, to: now)!,
                isFromMe: false
            ),
            ChatMessage(
                chatId: "2",
                roomId: roomId,
                content: "네, 안녕하세요. 어떤 부분이 궁금하신가요?",
                senderId: "me",
                senderNickname: "나",
                senderProfileImage: nil,
                createdAt: calendar.date(byAdding: .minute, value: -28, to: now)!,
                isFromMe: true
            ),
            ChatMessage(
                chatId: "3",
                roomId: roomId,
                content: "혹시 이번 주 토요일에 방문 가능할까요?",
                senderId: "me",
                senderNickname: "나",
                senderProfileImage: nil,
                createdAt: calendar.date(byAdding: .minute, value: -27, to: now)!,
                isFromMe: true
            ),
            ChatMessage(
                chatId: "4",
                roomId: roomId,
                content: "네, 토요일 오후 2시에 가능합니다. 괜찮으시면 예약해드릴게요!",
                senderId: "other-user",
                senderNickname: "김부동산",
                senderProfileImage: nil,
                createdAt: calendar.date(byAdding: .minute, value: -25, to: now)!,
                isFromMe: false
            ),
            ChatMessage(
                chatId: "5",
                roomId: roomId,
                content: "좋습니다. 그 시간에 방문하겠습니다.",
                senderId: "me",
                senderNickname: "나",
                senderProfileImage: nil,
                createdAt: calendar.date(byAdding: .minute, value: -20, to: now)!,
                isFromMe: true
            )
        ]
    }
}
