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

    init(repository: ChatRepository, authService: AuthServiceProtocol) {
        self.repository = repository
        self.authService = authService
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
        let chatRooms = input.viewDidLoad
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
            .asDriver(onErrorJustReturn: [])

        let navigateToChatRoom = input.chatRoomTapped
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            chatRooms: chatRooms,
            navigateToChatRoom: navigateToChatRoom
        )
    }
}
