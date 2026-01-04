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
    private let keychainManager: KeychainManager
    private let disposeBag = DisposeBag()

    init(repository: ChatRepository, keychainManager: KeychainManager = .shared) {
        self.repository = repository
        self.keychainManager = keychainManager
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
                guard let currentUserId = owner.getCurrentUserId() else {
                    Logger.auth.error("Failed to extract user ID from token")
                    return .just([])
                }

                return owner.repository.getChatRooms()
                    .asObservable()
                    .map { response in
                        response.data.compactMap { dto in
                            dto.toDomain(currentUserId: currentUserId)
                        }
                    }
                    .catch { error in
                        Logger.network.error("Failed to fetch chat rooms - \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToChatRoom = input.chatRoomTapped
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            chatRooms: chatRooms,
            navigateToChatRoom: navigateToChatRoom
        )
    }

    private func getCurrentUserId() -> String? {
        guard let accessToken = try? keychainManager.loadAccessToken() else {
            return nil
        }

        let segments = accessToken.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }

        var base64 = segments[1]
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["id"] as? String else {
            return nil
        }

        return userId
    }

}
