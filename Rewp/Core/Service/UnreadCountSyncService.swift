//
//  UnreadCountSyncService.swift
//  Rewp
//
//  Created by 금가경 on 01/05/26.
//

import Foundation
import RxSwift
import OSLog

final class UnreadCountSyncService {
    private let chatRepository: ChatRepository
    private let authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()
    private var currentChatRoomId: String?

    init(chatRepository: ChatRepository, authService: AuthServiceProtocol) {
        self.chatRepository = chatRepository
        self.authService = authService

        NotificationCenter.default.rx
            .notification(.currentChatRoomChanged)
            .compactMap { $0.userInfo?["info"] as? CurrentChatRoomInfo }
            .withUnretained(self)
            .subscribe(onNext: { owner, info in
                owner.currentChatRoomId = info.roomId
            })
            .disposed(by: disposeBag)
    }

    func syncAllUnreadCounts() -> Completable {
        guard let currentUserId = authService.currentUserId else {
            Logger.chat.error("Failed to extract user ID for unread count sync")
            return .empty()
        }

        return chatRepository.getChatRooms()
            .asObservable()
            .withUnretained(self)
            .flatMap { owner, response -> Observable<Void> in
                let rooms = response.data.compactMap { dto in
                    dto.toDomain(currentUserId: currentUserId)
                }

                return owner.chatRepository.saveChatRoomsToLocal(rooms)
                    .andThen(Observable.just(()))
                    .withUnretained(owner)
                    .flatMap { owner, _ -> Observable<Void> in
                        let syncOperations = rooms.compactMap { room -> Completable? in
                            guard owner.currentChatRoomId != room.roomId else {
                                return nil
                            }

                            return owner.syncUnreadCountForRoom(roomId: room.roomId, updatedAt: room.updatedAt)
                        }

                        guard !syncOperations.isEmpty else {
                            return Observable.just(())
                        }

                        return Completable.zip(syncOperations)
                            .andThen(Observable.just(()))
                    }
            }
            .ignoreElements()
            .asCompletable()
    }

    private func syncUnreadCountForRoom(roomId: String, updatedAt: Date?) -> Completable {
        guard let _ = authService.currentUserId else {
            return .empty()
        }

        let lastReadAt = chatRepository.getLastReadAt(roomId: roomId)

        Logger.chat.notice("Sync check - roomId: \(roomId, privacy: .public)")
        Logger.chat.notice("  lastReadAt: \(lastReadAt?.description ?? "nil", privacy: .public)")
        Logger.chat.notice("  updatedAt: \(updatedAt?.description ?? "nil", privacy: .public)")

        if let lastReadAt = lastReadAt,
           let updatedAt = updatedAt,
           lastReadAt >= updatedAt {
            Logger.chat.notice("All messages read - roomId: \(roomId, privacy: .public), lastReadAt >= updatedAt")

            return chatRepository.updateUnreadCount(roomId: roomId, count: 0)
                .do(onCompleted: {
                    Logger.chat.notice("Unread count reset to 0 - roomId: \(roomId, privacy: .public)")
                })
        }

        if lastReadAt == nil {
            Logger.chat.notice("Condition failed - lastReadAt is nil")
        } else if updatedAt == nil {
            Logger.chat.notice("Condition failed - updatedAt is nil")
        } else {
            Logger.chat.notice("Condition failed - lastReadAt < updatedAt")
        }

        return chatRepository.fetchMessagesFromRemote(roomId: roomId, after: lastReadAt)
            .withUnretained(self)
            .flatMap { owner, messages -> Single<Void> in
                let unreadCount = messages.filter { !$0.isFromMe }.count

                return owner.chatRepository.updateUnreadCount(roomId: roomId, count: unreadCount)
                    .do(onCompleted: {
                        Logger.chat.notice("Unread count synced - roomId: \(roomId, privacy: .public), count: \(unreadCount, privacy: .public)")
                    })
                    .andThen(Single.just(()))
            }
            .ignoreElements()
            .asCompletable()
            .catch { error in
                Logger.chat.error("Failed to sync unread count for room \(roomId, privacy: .public) - \(error.localizedDescription)")
                return .empty()
            }
    }
}
