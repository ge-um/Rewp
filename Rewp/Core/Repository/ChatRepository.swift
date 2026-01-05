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

    func fetchMessagesFromLocal(roomId: String) -> Observable<[ChatMessage]>
    func fetchMessagesFromRemote(roomId: String, after: Date?) -> Observable<[ChatMessage]>
    func saveMessageToLocal(_ message: ChatMessage, sendStatus: SendStatus?, tempId: String?) -> Completable
    func saveMessagesToLocal(_ messages: [ChatMessage]) -> Completable
    func getLastMessageDate(roomId: String) -> Date?
    func deleteTempMessage(tempId: String) -> Completable
    func isMessageExists(chatId: String) -> Bool

    func incrementUnreadCount(roomId: String) -> Completable
    func markAsRead(roomId: String) -> Completable
    func updateLastMessage(roomId: String, content: String, date: Date) -> Completable
}

extension ChatRepository {
    func saveMessageToLocal(_ message: ChatMessage) -> Completable {
        return saveMessageToLocal(message, sendStatus: nil, tempId: nil)
    }
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

    func fetchMessagesFromLocal(roomId: String) -> Observable<[ChatMessage]> {
        return localStorage.fetchMessages(roomId: roomId)
    }

    func fetchMessagesFromRemote(roomId: String, after: Date?) -> Observable<[ChatMessage]> {
        guard let currentUserId = authService.currentUserId else {
            return .just([])
        }

        let nextString: String?
        if let after = after {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            nextString = formatter.string(from: after)
        } else {
            nextString = nil
        }

        return getChatHistory(roomId: roomId, next: nextString)
            .asObservable()
            .map { response in
                response.data.map { dto in
                    dto.toDomain(currentUserId: currentUserId)
                }
            }
    }

    func saveMessageToLocal(_ message: ChatMessage, sendStatus: SendStatus?, tempId: String?) -> Completable {
        return localStorage.saveMessage(message, sendStatus: sendStatus, tempId: tempId)
    }

    func saveMessagesToLocal(_ messages: [ChatMessage]) -> Completable {
        return localStorage.saveMessages(messages)
    }

    func getLastMessageDate(roomId: String) -> Date? {
        return localStorage.getLastMessageDate(roomId: roomId)
    }

    func deleteTempMessage(tempId: String) -> Completable {
        return localStorage.deleteTempMessage(tempId: tempId)
    }

    func isMessageExists(chatId: String) -> Bool {
        return localStorage.isMessageExists(chatId: chatId)
    }

    func incrementUnreadCount(roomId: String) -> Completable {
        return localStorage.incrementUnreadCount(roomId: roomId)
    }

    func markAsRead(roomId: String) -> Completable {
        return localStorage.markAsRead(roomId: roomId)
    }

    func updateLastMessage(roomId: String, content: String, date: Date) -> Completable {
        return localStorage.updateLastMessage(roomId: roomId, content: content, date: date)
    }
}
