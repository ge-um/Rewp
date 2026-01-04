//
//  ChatLocalStorage.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import RealmSwift
import RxSwift

final class ChatLocalStorage {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider = .shared) {
        self.realmProvider = realmProvider
    }

    func saveChatRoom(_ room: ChatRoom) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let roomObject = ChatRoomObject.fromDomain(room)

                try realm.write {
                    realm.add(roomObject, update: .modified)
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func fetchChatRooms() -> Observable<[ChatRoom]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatLocalStorage", code: -1))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let rooms = realm.objects(ChatRoomObject.self)
                    .sorted(byKeyPath: "lastMessageDate", ascending: false)

                let chatRooms = rooms.map { $0.toDomain() }
                observer.onNext(Array(chatRooms))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func deleteChatRoom(roomId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        realm.delete(room)
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func saveMessage(_ message: ChatMessage, isSent: Bool = true, tempId: String? = nil) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let messageObject = ChatMessageObject.fromDomain(message, isSent: isSent, tempId: tempId)

                try realm.write {
                    realm.add(messageObject, update: .modified)
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func saveMessages(_ messages: [ChatMessage]) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let messageObjects = messages.map { ChatMessageObject.fromDomain($0) }

                try realm.write {
                    realm.add(messageObjects, update: .modified)
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func fetchMessages(roomId: String) -> Observable<[ChatMessage]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatLocalStorage", code: -1))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let messages = realm.objects(ChatMessageObject.self)
                    .filter("roomId == %@", roomId)
                    .sorted(byKeyPath: "createdAt", ascending: true)

                let chatMessages = messages.map { $0.toDomain() }
                observer.onNext(Array(chatMessages))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func isMessageExists(chatId: String) -> Bool {
        do {
            let realm = try realmProvider.realm()
            return realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) != nil
        } catch {
            return false
        }
    }

    func getLastMessageDate(roomId: String) -> Date? {
        do {
            let realm = try realmProvider.realm()
            let messages = realm.objects(ChatMessageObject.self)
                .filter("roomId == %@", roomId)
                .sorted(byKeyPath: "createdAt", ascending: false)

            return messages.first?.createdAt
        } catch {
            return nil
        }
    }

    func incrementUnreadCount(roomId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        room.unreadCount += 1
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func getUnreadCount(roomId: String) -> Int {
        do {
            let realm = try realmProvider.realm()
            let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId)
            return room?.unreadCount ?? 0
        } catch {
            return 0
        }
    }

    func markAsRead(roomId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        room.unreadCount = 0
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func getFailedMessages(roomId: String) -> Observable<[ChatMessage]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "ChatLocalStorage", code: -1))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let messages = realm.objects(ChatMessageObject.self)
                    .filter("roomId == %@ AND isSent == false", roomId)
                    .sorted(byKeyPath: "createdAt", ascending: true)

                let chatMessages = messages.map { $0.toDomain() }
                observer.onNext(Array(chatMessages))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func updateMessageSentStatus(tempId: String, isSent: Bool, chatId: String?) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                guard let message = realm.objects(ChatMessageObject.self)
                    .filter("tempId == %@", tempId).first else {
                    completable(.error(NSError(domain: "ChatLocalStorage", code: -2)))
                    return Disposables.create()
                }

                try realm.write {
                    message.isSent = isSent
                    if let chatId = chatId {
                        message.chatId = chatId
                        message.tempId = nil
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func deleteTempMessage(tempId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()
                let messages = realm.objects(ChatMessageObject.self)
                    .filter("tempId == %@", tempId)

                try realm.write {
                    realm.delete(messages)
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func updateLastMessage(roomId: String, content: String, date: Date) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "ChatLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                let realm = try self.realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        room.lastMessage = content
                        room.lastMessageDate = date
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }
}
