//
//  ChatRoomPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class ChatRoomPresenter {
    private let roomId: String
    private let roomTitle: String
    private let socketService: SocketServiceProtocol
    private let chatRepository: ChatRepository
    private let disposeBag = DisposeBag()

    init(roomId: String, roomTitle: String, socketService: SocketServiceProtocol, chatRepository: ChatRepository) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.socketService = socketService
        self.chatRepository = chatRepository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillDisappear: Observable<Void>
        let sendButtonTapped: Observable<String>
    }

    struct Output {
        let title: Driver<String>
        let messages: Driver<[ChatMessage]>
        let messageSent: Driver<Void>
        let isConnected: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let messagesRelay = BehaviorRelay<[ChatMessage]>(value: [])

        input.viewDidLoad
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.socketService.connect(roomId: owner.roomId)
                Logger.socket.notice("Chat room loaded - \(owner.roomId, privacy: .public)")
            })
            .disposed(by: disposeBag)

        input.viewWillDisappear
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.socketService.disconnect()
                Logger.socket.notice("Chat room closed - \(owner.roomId, privacy: .public)")
            })
            .disposed(by: disposeBag)

        socketService.receivedMessage
            .withUnretained(self)
            .subscribe(onNext: { owner, message in
                var currentMessages = messagesRelay.value
                currentMessages.append(message)
                messagesRelay.accept(currentMessages)
                Logger.socket.notice("Message added to list - total: \(currentMessages.count, privacy: .public)")
            })
            .disposed(by: disposeBag)

        let messageSent = input.sendButtonTapped
            .withUnretained(self)
            .flatMapLatest { owner, content in
                owner.chatRepository.sendMessage(roomId: owner.roomId, content: content, files: nil)
                    .asObservable()
                    .catch { error in
                        Logger.socket.error("Failed to send message - \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            title: .just(roomTitle),
            messages: messagesRelay.asDriver(),
            messageSent: messageSent,
            isConnected: socketService.isConnected.asDriver(onErrorJustReturn: false)
        )
    }
}
