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
    case getChatHistory(roomId: String, next: String?)
    case uploadFiles(roomId: String, files: [Data])
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
        case .getChatHistory(let roomId, _):
            return "/chats/\(roomId)"
        case .uploadFiles(let roomId, _):
            return "/chats/\(roomId)/files"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getChatRooms, .getChatHistory:
            return .get
        case .createChatRoom, .sendMessage, .uploadFiles:
            return .post
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .uploadFiles:
            return [
                "Content-Type": "multipart/form-data",
                "SesacKey": NetworkConfig.rewpKey
            ]
        default:
            return [
                "Content-Type": "application/json",
                "SesacKey": NetworkConfig.rewpKey
            ]
        }
    }

    var body: Encodable? {
        switch self {
        case .getChatRooms, .getChatHistory, .uploadFiles:
            return nil
        case .createChatRoom(let opponentId):
            return CreateChatRoomRequest(opponent_id: opponentId)
        case .sendMessage(_, let content, let files):
            return SendMessageRequest(content: content, files: files)
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .getChatHistory(_, let next):
            if let next = next {
                return ["next": next]
            }
            return nil
        default:
            return nil
        }
    }
}
