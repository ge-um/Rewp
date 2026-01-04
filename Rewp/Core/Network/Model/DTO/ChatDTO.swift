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
