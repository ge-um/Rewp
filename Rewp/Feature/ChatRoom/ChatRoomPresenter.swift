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
                guard !message.isFromMe else { return }

                var currentMessages = messagesRelay.value
                currentMessages.append(message)
                messagesRelay.accept(currentMessages)
                Logger.socket.notice("Message added to list - total: \(currentMessages.count, privacy: .public)")
            })
            .disposed(by: disposeBag)

        let messageSent = input.sendButtonTapped
            .withUnretained(self)
            .flatMapLatest { owner, content -> Observable<Void> in
                guard let currentUserId = owner.authService.currentUserId else {
                    Logger.auth.error("Failed to extract user ID from token")
                    return .empty()
                }

                return owner.chatRepository.sendMessage(roomId: owner.roomId, content: content, files: nil)
                    .asObservable()
                    .flatMap { response -> Observable<Void> in
                        let message = response.toDomain(currentUserId: currentUserId)

                        return owner.chatRepository.saveMessageToLocal(message)
                            .do(onCompleted: {
                                var currentMessages = messagesRelay.value
                                currentMessages.append(message)
                                messagesRelay.accept(currentMessages)
                                Logger.socket.notice("Message sent and saved - \(message.chatId, privacy: .public)")
                            })
                            .andThen(Observable.just(()))
                    }
                    .catch { error in
                        Logger.socket.error("Failed to send message - \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            title: .just(roomTitle),
            messages: messagesRelay.asDriver(),
            messageSent: messageSent,
            isConnected: socketService.isConnected.asDriver(onErrorJustReturn: false)
        )
    }

    private func loadChatHistory(messagesRelay: BehaviorRelay<[ChatMessage]>) {
        let localMessages = chatRepository.fetchMessagesFromLocal(roomId: roomId)
            .catch { error in
                Logger.network.error("Failed to fetch local messages - \(error.localizedDescription)")
                return .just([])
            }

        let lastDate = chatRepository.getLastMessageDate(roomId: roomId)

        let remoteMessages = chatRepository.fetchMessagesFromRemote(roomId: roomId, after: lastDate)
            .flatMap { [weak self] messages -> Observable<[ChatMessage]> in
                guard let self = self else { return .just([]) }
                return self.chatRepository.saveMessagesToLocal(messages)
                    .andThen(self.chatRepository.fetchMessagesFromLocal(roomId: self.roomId))
            }
            .catch { error in
                Logger.network.error("Failed to fetch remote messages - \(error.localizedDescription)")
                return .empty()
            }

        Observable.concat([localMessages, remoteMessages])
            .withUnretained(self)
            .subscribe(onNext: { owner, messages in
                messagesRelay.accept(messages)
                Logger.network.notice("Chat history loaded - count: \(messages.count, privacy: .public)")
            })
            .disposed(by: disposeBag)
    }
}
