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
import UIKit

final class ChatRoomPresenter {
    private let roomId: String
    private let roomTitle: String
    private let socketService: SocketServiceProtocol
    private let chatRepository: ChatRepository
    private let authService: AuthServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let disposeBag = DisposeBag()

    init(
        roomId: String,
        roomTitle: String,
        socketService: SocketServiceProtocol,
        chatRepository: ChatRepository,
        authService: AuthServiceProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.socketService = socketService
        self.chatRepository = chatRepository
        self.authService = authService
        self.networkMonitor = networkMonitor
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillDisappear: Observable<Void>
        let sendButtonTapped: Observable<String>
        let retryMessageTapped: Observable<String>
        let deleteMessageTapped: Observable<String>
        let attachButtonTapped: Observable<Void>
        let filesSelected: Observable<[UIImage]>
        let photoSendConfirmed: Observable<(images: [UIImage], text: String)>
    }

    struct Output {
        let title: Driver<String>
        let messages: Driver<[ChatMessage]>
        let messageSent: Driver<Void>
        let isConnected: Driver<Bool>
        let isNetworkConnected: Driver<Bool>
        let showAttachmentSheet: Driver<Void>
        let showPhotoPreview: Driver<[UIImage]>
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

        NotificationCenter.default.rx
            .notification(.appWillEnterForeground)
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<Void> in
                owner.socketService.connect(roomId: owner.roomId)

                return owner.chatRepository
                    .syncMessages(roomId: owner.roomId)
                    .do(onNext: { messages in
                        messagesRelay.accept(messages)
                        Logger.socket.notice("Messages synced on foreground - count: \(messages.count, privacy: .public)")
                    })
                    .map { _ in () }
                    .catch { error in
                        Logger.socket.error("Failed to sync messages on foreground - \(error.localizedDescription)")
                        return .just(())
                    }
            }
            .subscribe()
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

        let showAttachmentSheetRelay = PublishRelay<Void>()

        input.attachButtonTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                showAttachmentSheetRelay.accept(())
            })
            .disposed(by: disposeBag)

        let showPhotoPreviewRelay = PublishRelay<[UIImage]>()

        input.filesSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, images in
                guard images.count <= 5 else {
                    Logger.ui.error("Too many files selected - \(images.count)")
                    return
                }
                showPhotoPreviewRelay.accept(images)
            })
            .disposed(by: disposeBag)

        input.photoSendConfirmed
            .withUnretained(self)
            .flatMapLatest { owner, data -> Observable<Void> in
                let (images, text) = data
                guard let currentUserId = owner.authService.currentUserId else {
                    return .empty()
                }

                let imageDatas = images.compactMap { $0.jpegData(compressionQuality: 0.7) }

                guard !imageDatas.isEmpty else {
                    return .empty()
                }

                for data in imageDatas {
                    let sizeInMB = Double(data.count) / (1024 * 1024)
                    if sizeInMB > 5.0 {
                        Logger.ui.error("File size exceeded - \(sizeInMB)MB")
                        return .empty()
                    }
                }

                return owner.chatRepository.uploadFiles(roomId: owner.roomId, images: imageDatas)
                    .asObservable()
                    .flatMap { filePaths -> Observable<Void> in
                        let tempId = UUID().uuidString
                        let tempMessage = ChatMessage(
                            chatId: tempId,
                            roomId: owner.roomId,
                            content: text,
                            senderId: currentUserId,
                            senderNickname: "나",
                            senderProfileImage: nil,
                            createdAt: Date(),
                            isFromMe: true,
                            sendStatus: .sending,
                            tempId: nil,
                            files: filePaths
                        )

                        var currentMessages = messagesRelay.value
                        currentMessages.append(tempMessage)
                        messagesRelay.accept(currentMessages)

                        return owner.chatRepository.sendMessage(
                            roomId: owner.roomId,
                            content: text,
                            files: filePaths
                        )
                        .asObservable()
                        .flatMap { response -> Observable<Void> in
                            let serverMessage = response.toDomain(currentUserId: currentUserId)

                            return owner.chatRepository.saveMessageToLocal(serverMessage)
                                .do(onCompleted: {
                                    var currentMessages = messagesRelay.value
                                    currentMessages.removeAll { $0.chatId == tempId }
                                    currentMessages.append(serverMessage)
                                    messagesRelay.accept(currentMessages)
                                })
                                .andThen(Observable.just(()))
                        }
                        .catch { error -> Observable<Void> in
                            Logger.socket.error("Failed to send file message")

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
                                tempId: tempId,
                                files: tempMessage.files
                            )

                            var currentMessages = messagesRelay.value
                            if let index = currentMessages.firstIndex(where: { $0.chatId == tempId }) {
                                currentMessages[index] = failedMessage
                            }
                            messagesRelay.accept(currentMessages)

                            return .empty()
                        }
                    }
                    .catch { error in
                        Logger.network.error("File upload failed")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        networkMonitor.isConnected
            .distinctUntilChanged()
            .skip(1)
            .filter { $0 }
            .withUnretained(self)
            .flatMapLatest { owner, _ -> Observable<Void> in
                owner.socketService.connect(roomId: owner.roomId)

                return owner.chatRepository
                    .syncMessages(roomId: owner.roomId)
                    .do(onNext: { messages in
                        messagesRelay.accept(messages)
                        Logger.socket.notice("Messages synced on network recovery - count: \(messages.count, privacy: .public)")
                    })
                    .map { _ in () }
                    .catch { error in
                        Logger.socket.error("Failed to sync messages on network recovery - \(error.localizedDescription)")
                        return .just(())
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(
            title: .just(roomTitle),
            messages: messagesRelay.asDriver(),
            messageSent: messageSent,
            isConnected: socketService.isConnected.asDriver(onErrorJustReturn: false),
            isNetworkConnected: networkMonitor.isConnected.asDriver(onErrorJustReturn: true),
            showAttachmentSheet: showAttachmentSheetRelay.asDriver(onErrorDriveWith: .empty()),
            showPhotoPreview: showPhotoPreviewRelay.asDriver(onErrorDriveWith: .empty())
        )
    }

    private func loadChatHistory(messagesRelay: BehaviorRelay<[ChatMessage]>) {
        let localMessages = chatRepository.fetchMessagesFromLocal(roomId: roomId)
            .catch { error in
                Logger.network.error("Failed to fetch local messages - \(error.localizedDescription)")
                return .just([])
            }

        let remoteMessages = chatRepository.syncMessages(roomId: roomId)
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
