//
//  ChatDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation

struct CreateChatRoomRequest: Encodable {
    let opponent_id: String
}

struct CreateChatRoomResponse: Decodable {
    let room_id: String
    let createdAt: String
    let updatedAt: String
    let participants: [ParticipantDTO]
    let lastChat: LastChatDTO?
}

struct ParticipantDTO: Decodable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}

struct LastChatDTO: Decodable {
    let chat_id: String
    let room_id: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ParticipantDTO
    let files: [String]?
}

struct SendMessageRequest: Encodable {
    let content: String
    let files: [String]?
}

struct SendMessageResponse: Decodable {
    let chat_id: String
    let room_id: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: ParticipantDTO
    let files: [String]?
}

typealias ChatRoomDTO = CreateChatRoomResponse

struct GetChatRoomsResponse: Decodable {
    let data: [ChatRoomDTO]
}

struct GetChatHistoryResponse: Decodable {
    let data: [ChatMessageDTO]
}

typealias ChatMessageDTO = LastChatDTO

extension ChatRoomDTO {
    func toDomain(currentUserId: String) -> ChatRoom? {
        guard let opponent = participants.first(where: { $0.user_id != currentUserId }) else {
            return nil
        }

        let lastMessageText: String
        let lastMessageDate: Date

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lastMessageDate = formatter.date(from: updatedAt) ?? Date()

        if let lastChat = lastChat {
            lastMessageText = lastChat.content
        } else {
            lastMessageText = ""
        }

        return ChatRoom(
            roomId: room_id,
            participantId: opponent.user_id,
            participantName: opponent.nick,
            participantProfileImage: opponent.profileImage,
            lastMessage: lastMessageText,
            lastMessageDate: lastMessageDate,
            unreadCount: 0
        )
    }
}

extension ChatMessageDTO {
    func toDomain(currentUserId: String) -> ChatMessage {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAt) ?? Date()

        return ChatMessage(
            chatId: chat_id,
            roomId: room_id,
            content: content,
            senderId: sender.user_id,
            senderNickname: sender.nick,
            senderProfileImage: sender.profileImage,
            createdAt: date,
            isFromMe: sender.user_id == currentUserId,
            sendStatus: .sent,
            tempId: nil
        )
    }
}

extension SendMessageResponse {
    func toDomain(currentUserId: String) -> ChatMessage {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAt) ?? Date()

        return ChatMessage(
            chatId: chat_id,
            roomId: room_id,
            content: content,
            senderId: sender.user_id,
            senderNickname: sender.nick,
            senderProfileImage: sender.profileImage,
            createdAt: date,
            isFromMe: sender.user_id == currentUserId,
            sendStatus: .sent,
            tempId: nil
        )
    }
}
