//
//  ChatRoomPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ChatRoomPresenter {
    private let roomId: String
    private let roomTitle: String
    private let disposeBag = DisposeBag()

    init(roomId: String, roomTitle: String) {
        self.roomId = roomId
        self.roomTitle = roomTitle
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let sendButtonTapped: Observable<String>
    }

    struct Output {
        let title: Driver<String>
        let messages: Driver<[ChatMessage]>
        let messageSent: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let messagesRelay = BehaviorRelay<[ChatMessage]>(value: [])

        input.viewDidLoad
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let mockMessages = ChatMessage.mockMessages(roomId: owner.roomId)
                messagesRelay.accept(mockMessages)
            })
            .disposed(by: disposeBag)

        let messageSent = input.sendButtonTapped
            .withUnretained(self)
            .map { owner, content -> Void in
                let newMessage = ChatMessage(
                    chatId: UUID().uuidString,
                    roomId: owner.roomId,
                    content: content,
                    senderId: "me",
                    senderNickname: "나",
                    senderProfileImage: nil,
                    createdAt: Date(),
                    isFromMe: true
                )
                var currentMessages = messagesRelay.value
                currentMessages.append(newMessage)
                messagesRelay.accept(currentMessages)
                return ()
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            title: .just(roomTitle),
            messages: messagesRelay.asDriver(),
            messageSent: messageSent
        )
    }
}
