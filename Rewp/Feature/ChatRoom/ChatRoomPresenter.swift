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
    private let authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()

    init(
        roomId: String,
        roomTitle: String,
        socketService: SocketServiceProtocol,
        chatRepository: ChatRepository,
        authService: AuthServiceProtocol
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.socketService = socketService
        self.chatRepository = chatRepository
        self.authService = authService
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
                owner.loadChatHistory(messagesRelay: messagesRelay)
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

    private func loadChatHistory(messagesRelay: BehaviorRelay<[ChatMessage]>) {
        guard let currentUserId = authService.currentUserId else {
            Logger.auth.error("Failed to extract user ID from token")
            return
        }

        chatRepository.getChatHistory(roomId: roomId, next: nil)
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, response in
                let messages = response.data.map { $0.toDomain(currentUserId: currentUserId) }
                messagesRelay.accept(messages)
                Logger.network.notice("Chat history loaded - count: \(messages.count, privacy: .public)")
            }, onError: { error in
                Logger.network.error("Failed to load chat history - \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}
