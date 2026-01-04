//
//  ChatRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import Alamofire

enum ChatRouter {
    case getChatRooms
    case createChatRoom(opponentId: String)
    case sendMessage(roomId: String, content: String, files: [String]?)
}

extension ChatRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .getChatRooms, .createChatRoom:
            return "/chats"
        case .sendMessage(let roomId, _, _):
            return "/chats/\(roomId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getChatRooms:
            return .get
        case .createChatRoom, .sendMessage:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }

    var body: Encodable? {
        switch self {
        case .getChatRooms:
            return nil
        case .createChatRoom(let opponentId):
            return CreateChatRoomRequest(opponent_id: opponentId)
        case .sendMessage(_, let content, let files):
            return SendMessageRequest(content: content, files: files)
        }
    }
}
