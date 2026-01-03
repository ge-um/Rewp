//
//  ChatListPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation
import RxCocoa
import RxSwift

final class ChatListPresenter {
    private let disposeBag = DisposeBag()

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
            .map { _ in
                ChatRoom.mockChatRooms()
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
