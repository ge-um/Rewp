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
        let retryMessageTapped: Observable<String>
        let deleteMessageTapped: Observable<String>
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

                NotificationCenter.default.post(
                    name: .currentChatRoomChanged,
                    object: nil,
                    userInfo: ["info": CurrentChatRoomInfo(roomId: owner.roomId)]
                )

                let now = Date()

                Observable.zip(
                    owner.chatRepository.markAsRead(roomId: owner.roomId).asObservable(),
                    owner.chatRepository.updateLastReadAt(roomId: owner.roomId, date: now).asObservable()
                )
                .subscribe(onError: { error in
                    Logger.socket.error("Failed to mark as read or update lastReadAt - \(error.localizedDescription)")
                }, onCompleted: {
                    Logger.socket.notice("Chat room marked as read and lastReadAt updated - \(owner.roomId, privacy: .public)")
                })
                .disposed(by: owner.disposeBag)

                Logger.socket.notice("Chat room loaded - \(owner.roomId, privacy: .public)")
                owner.loadChatHistory(messagesRelay: messagesRelay)
            })
            .disposed(by: disposeBag)

        input.viewWillDisappear
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.socketService.disconnect()

                NotificationCenter.default.post(
                    name: .currentChatRoomChanged,
                    object: nil,
                    userInfo: ["info": CurrentChatRoomInfo(roomId: nil)]
                )

                Logger.socket.notice("Chat room closed - \(owner.roomId, privacy: .public)")
            })
            .disposed(by: disposeBag)

        socketService.receivedMessage
            .withUnretained(self)
            .filter { owner, message in
                guard !message.isFromMe else { return false }

                let isDuplicate = owner.chatRepository.isMessageExists(chatId: message.chatId)
                if isDuplicate {
                    Logger.socket.notice("Duplicate message ignored - chatId: \(message.chatId, privacy: .public)")
                    return false
                }

                return true
            }
            .flatMapLatest { owner, message -> Observable<ChatMessage> in
                return owner.chatRepository.saveMessageToLocal(message)
                    .andThen(Observable.just(message))
                    .catch { error in
                        Logger.socket.error("Failed to save socket message to Realm - chatId: \(message.chatId, privacy: .public), error: \(error.localizedDescription)")
                        return Observable.just(message)
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, message in
                var currentMessages = messagesRelay.value
                currentMessages.append(message)
                messagesRelay.accept(currentMessages)
                Logger.socket.notice("Socket message saved and displayed - chatId: \(message.chatId, privacy: .public)")
            })
            .disposed(by: disposeBag)

        let messageSent = input.sendButtonTapped
            .withUnretained(self)
            .flatMapLatest { owner, content -> Observable<Void> in
                guard let currentUserId = owner.authService.currentUserId else {
                    Logger.auth.error("Failed to extract user ID from token")
                    return .empty()
                }

                let tempId = UUID().uuidString
                let tempMessage = ChatMessage(
                    chatId: tempId,
                    roomId: owner.roomId,
                    content: content,
                    senderId: currentUserId,
                    senderNickname: "나",
                    senderProfileImage: nil,
                    createdAt: Date(),
                    isFromMe: true,
                    sendStatus: .sending,
                    tempId: nil
                )

                var currentMessages = messagesRelay.value
                currentMessages.append(tempMessage)
                messagesRelay.accept(currentMessages)

                return owner.chatRepository.sendMessage(roomId: owner.roomId, content: content, files: nil)
                    .asObservable()
                    .flatMap { response -> Observable<Void> in
                        let serverMessage = response.toDomain(currentUserId: currentUserId)

                        return owner.chatRepository.saveMessageToLocal(serverMessage)
                            .do(onCompleted: {
                                var currentMessages = messagesRelay.value

                                currentMessages.removeAll { $0.chatId == tempId }

                                currentMessages.append(serverMessage)

                                messagesRelay.accept(currentMessages)
                                Logger.socket.notice("Message sent - \(serverMessage.chatId, privacy: .public)")
                            })
                            .andThen(Observable.just(()))
                    }
                    .catch { error -> Observable<Void> in
                        Logger.socket.error("Failed to send message - \(error.localizedDescription)")

                        let failedMessage = ChatMessage(
                            chatId: tempMessage.chatId,
                            roomId: tempMessage.roomId,
                            content: tempMessage.content,
                            senderId: tempMessage.senderId,
                            senderNickname: tempMessage.senderNickname,
                            senderProfileImage: tempMessage.senderProfileImage,
                            createdAt: tempMessage.createdAt,
                            isFromMe: tempMessage.isFromMe,
                            sendStatus: .failed,
                            tempId: tempId
                        )

                        return owner.chatRepository.saveMessageToLocal(failedMessage, sendStatus: .failed, tempId: tempId)
                            .do(onCompleted: {
                                var currentMessages = messagesRelay.value
                                if let index = currentMessages.firstIndex(where: { $0.chatId == tempId }) {
                                    currentMessages[index] = failedMessage
                                }
                                messagesRelay.accept(currentMessages)
                                Logger.socket.error("Message marked as failed - tempId: \(tempId, privacy: .public)")
                            })
                            .andThen(Observable.just(()))
                            .catch { _ in .empty() }
                    }
            }
            .asDriver(onErrorDriveWith: .empty())

        input.retryMessageTapped
            .withUnretained(self)
            .flatMapLatest { owner, tempId -> Observable<Void> in
                guard let currentUserId = owner.authService.currentUserId else {
                    return .empty()
                }

                return owner.chatRepository.fetchMessagesFromLocal(roomId: owner.roomId)
                    .flatMap { messages -> Observable<Void> in
                        guard let failedMessage = messages.first(where: { $0.tempId == tempId }) else {
                            return .empty()
                        }

                        let sendingMessage = ChatMessage(
                            chatId: failedMessage.chatId,
                            roomId: failedMessage.roomId,
                            content: failedMessage.content,
                            senderId: failedMessage.senderId,
                            senderNickname: failedMessage.senderNickname,
                            senderProfileImage: failedMessage.senderProfileImage,
                            createdAt: failedMessage.createdAt,
                            isFromMe: failedMessage.isFromMe,
                            sendStatus: .sending,
                            tempId: tempId
                        )

                        var currentMessages = messagesRelay.value
                        if let index = currentMessages.firstIndex(where: { $0.tempId == tempId }) {
                            currentMessages[index] = sendingMessage
                        }
                        messagesRelay.accept(currentMessages)

                        return owner.chatRepository.sendMessage(
                            roomId: owner.roomId,
                            content: failedMessage.content,
                            files: nil
                        )
                        .asObservable()
                        .flatMap { response -> Observable<Void> in
                            let serverMessage = response.toDomain(currentUserId: currentUserId)

                            return owner.chatRepository.deleteTempMessage(tempId: tempId)
                                .andThen(owner.chatRepository.saveMessageToLocal(serverMessage))
                                .do(onCompleted: {
                                    var currentMessages = messagesRelay.value

                                    currentMessages.removeAll { $0.tempId == tempId }

                                    currentMessages.append(serverMessage)

                                    messagesRelay.accept(currentMessages)
                                    Logger.socket.notice("Message resent - \(serverMessage.chatId, privacy: .public)")
                                })
                                .andThen(Observable.just(()))
                        }
                        .catch { error in
                            Logger.socket.error("Failed to resend message - \(error.localizedDescription)")

                            let failedAgain = ChatMessage(
                                chatId: failedMessage.chatId,
                                roomId: failedMessage.roomId,
                                content: failedMessage.content,
                                senderId: failedMessage.senderId,
                                senderNickname: failedMessage.senderNickname,
                                senderProfileImage: failedMessage.senderProfileImage,
                                createdAt: failedMessage.createdAt,
                                isFromMe: failedMessage.isFromMe,
                                sendStatus: .failed,
                                tempId: tempId
                            )

                            var currentMessages = messagesRelay.value
                            if let index = currentMessages.firstIndex(where: { $0.tempId == tempId }) {
                                currentMessages[index] = failedAgain
                            }
                            messagesRelay.accept(currentMessages)

                            return .empty()
                        }
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        input.deleteMessageTapped
            .withUnretained(self)
            .flatMapLatest { owner, tempId -> Observable<Void> in
                return owner.chatRepository.deleteTempMessage(tempId: tempId)
                    .do(onCompleted: {
                        var currentMessages = messagesRelay.value
                        currentMessages.removeAll { $0.tempId == tempId }
                        messagesRelay.accept(currentMessages)
                        Logger.socket.notice("Failed message deleted - tempId: \(tempId, privacy: .public)")
                    })
                    .andThen(Observable.just(()))
                    .catch { error in
                        Logger.socket.error("Failed to delete message - \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

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
