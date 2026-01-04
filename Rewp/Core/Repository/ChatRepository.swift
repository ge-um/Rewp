//
//  ChatRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import RxSwift

protocol ChatRepository {
    func getChatRooms() -> Single<GetChatRoomsResponse>
    func createChatRoom(opponentId: String) -> Single<CreateChatRoomResponse>
    func sendMessage(roomId: String, content: String, files: [String]?) -> Single<SendMessageResponse>
    func getChatHistory(roomId: String, next: String?) -> Single<GetChatHistoryResponse>
}

final class ChatRepositoryImpl: ChatRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func getChatRooms() -> Single<GetChatRoomsResponse> {
        return authService.authenticatedRequest(ChatRouter.getChatRooms)
    }

    func createChatRoom(opponentId: String) -> Single<CreateChatRoomResponse> {
        return authService.authenticatedRequest(ChatRouter.createChatRoom(opponentId: opponentId))
    }

    func sendMessage(roomId: String, content: String, files: [String]?) -> Single<SendMessageResponse> {
        return authService.authenticatedRequest(ChatRouter.sendMessage(roomId: roomId, content: content, files: files))
    }

    func getChatHistory(roomId: String, next: String?) -> Single<GetChatHistoryResponse> {
        return authService.authenticatedRequest(ChatRouter.getChatHistory(roomId: roomId, next: next))
    }
}
