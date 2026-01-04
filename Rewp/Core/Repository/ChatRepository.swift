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

    func fetchChatRoomsFromLocal() -> Observable<[ChatRoom]>
    func saveChatRoomsToLocal(_ rooms: [ChatRoom]) -> Completable
}

final class ChatRepositoryImpl: ChatRepository {
    private let authService: AuthServiceProtocol
    private let localStorage: ChatLocalStorage

    init(authService: AuthServiceProtocol, localStorage: ChatLocalStorage) {
        self.authService = authService
        self.localStorage = localStorage
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

    func fetchChatRoomsFromLocal() -> Observable<[ChatRoom]> {
        return localStorage.fetchChatRooms()
    }

    func saveChatRoomsToLocal(_ rooms: [ChatRoom]) -> Completable {
        return Observable.from(rooms)
            .flatMap { [weak self] room -> Completable in
                guard let self = self else { return .empty() }
                return self.localStorage.saveChatRoom(room)
            }
            .toArray()
            .asCompletable()
    }
}
