//
//  ChatListPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation
import RxCocoa
import RxSwift
import OSLog

final class ChatListPresenter {
    private let repository: ChatRepository
    private let authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()
    private var currentChatRoomId: String?

    init(repository: ChatRepository, authService: AuthServiceProtocol) {
        self.repository = repository
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

    struct Input {
        let viewDidLoad: Observable<Void>
        let chatRoomTapped: Observable<ChatRoom>
    }

    struct Output {
        let chatRooms: Driver<[ChatRoom]>
        let navigateToChatRoom: Driver<ChatRoom>
    }

    func transform(input: Input) -> Output {
        let viewDidLoadRooms = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<[ChatRoom]> in
                guard let currentUserId = owner.authService.currentUserId else {
                    Logger.auth.error("Failed to extract user ID from token")
                    return .just([])
                }

                let localRooms = owner.repository.fetchChatRoomsFromLocal()
                    .catch { error in
                        Logger.network.error("Failed to fetch local chat rooms - \(error.localizedDescription)")
                        return .just([])
                    }

                let remoteRooms = owner.repository.getChatRooms()
                    .asObservable()
                    .map { response in
                        response.data.compactMap { dto in
                            dto.toDomain(currentUserId: currentUserId)
                        }
                    }
                    .flatMap { rooms -> Observable<[ChatRoom]> in
                        owner.repository.saveChatRoomsToLocal(rooms)
                            .andThen(owner.repository.fetchChatRoomsFromLocal())
                    }
                    .catch { error in
                        Logger.network.error("Failed to fetch remote chat rooms - \(error.localizedDescription)")
                        return .empty()
                    }

                return Observable.concat([localRooms, remoteRooms])
            }

        let fcmUpdate = NotificationCenter.default.rx
            .notification(.chatMessageReceived)
            .compactMap { $0.userInfo?["info"] as? ChatMessageReceivedInfo }
            .withUnretained(self)
            .flatMapLatest { owner, info -> Observable<[ChatRoom]> in
                return owner.handleChatMessageReceived(roomId: info.roomId)
            }

        let chatRoomExited = NotificationCenter.default.rx
            .notification(.currentChatRoomChanged)
            .compactMap { $0.userInfo?["info"] as? CurrentChatRoomInfo }
            .filter { $0.roomId == nil }
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<[ChatRoom]> in
                return owner.repository.fetchChatRoomsFromLocal()
                    .catch { error in
                        Logger.network.error("Failed to refresh chat rooms after exit - \(error.localizedDescription)")
                        return .just([])
                    }
            }

        let chatRooms = Observable.merge(viewDidLoadRooms, fcmUpdate, chatRoomExited)
            .asDriver(onErrorJustReturn: [])

        let navigateToChatRoom = input.chatRoomTapped
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            chatRooms: chatRooms,
            navigateToChatRoom: navigateToChatRoom
        )
    }

    private func handleChatMessageReceived(roomId: String) -> Observable<[ChatRoom]> {
        guard let currentUserId = authService.currentUserId else {
            return .just([])
        }

        return repository.getChatRooms()
            .asObservable()
            .withUnretained(self)
            .flatMap { owner, response -> Observable<[ChatRoom]> in
                let rooms = response.data.compactMap { dto in
                    dto.toDomain(currentUserId: currentUserId)
                }

                return owner.repository.saveChatRoomsToLocal(rooms)
                    .andThen(Observable.just(()))
                    .withUnretained(owner)
                    .flatMap { owner, _ -> Observable<[ChatRoom]> in
                        let updateUnread: Completable
                        if owner.currentChatRoomId != roomId {
                            updateUnread = owner.repository.incrementUnreadCount(roomId: roomId)
                        } else {
                            updateUnread = .empty()
                        }

                        return updateUnread
                            .andThen(owner.repository.fetchChatRoomsFromLocal())
                    }
            }
            .catch { error in
                Logger.network.error("Failed to handle FCM message - \(error.localizedDescription)")
                return self.repository.fetchChatRoomsFromLocal()
            }
    }
}
