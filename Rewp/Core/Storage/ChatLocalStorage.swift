//
//  ChatLocalStorage.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import OSLog
import RealmSwift
import RxSwift

final class ChatLocalStorage {
    private let realmProvider: RealmProvider

    init(realmProvider: RealmProvider = .shared) {
        self.realmProvider = realmProvider
    }

    func saveChatRoom(_ room: ChatRoom) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

                let existingLastReadAt: Date?
                if let existingRoom = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: room.roomId) {
                    existingLastReadAt = existingRoom.lastReadAt
                } else {
                    existingLastReadAt = nil
                }

                let roomObject = ChatRoomObject(
                    roomId: room.roomId,
                    participantId: room.participantId,
                    participantName: room.participantName,
                    participantProfileImage: room.participantProfileImage,
                    lastMessage: room.lastMessage,
                    lastMessageDate: room.lastMessageDate,
                    unreadCount: room.unreadCount,
                    lastReadAt: existingLastReadAt,
                    updatedAt: room.updatedAt
                )

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
        return Observable.create { [realmProvider] observer in
            do {
                let realm = try realmProvider.realm()
                let results = realm.objects(ChatRoomObject.self)
                    .sorted(byKeyPath: "updatedAt", ascending: false)

                let token = results.observe { changes in
                    switch changes {
                    case .initial(let results), .update(let results, _, _, _):
                        observer.onNext(Array(results.map { $0.toDomain() }))
                    case .error(let error):
                        observer.onError(error)
                    }
                }

                return Disposables.create {
                    token.invalidate()
                }
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
        }
        .subscribe(on: MainScheduler.instance)
    }

    func deleteChatRoom(roomId: String) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        realm.delete(room.messages)
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

    func saveMessage(_ message: ChatMessage, sendStatus: SendStatus? = nil, tempId: String? = nil) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()
                let messageObject = ChatMessageObject.fromDomain(message, sendStatus: sendStatus, tempId: tempId)

                try realm.write {
                    realm.add(messageObject, update: .modified)

                    if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: message.roomId) {
                        if !room.messages.contains(where: { $0.chatId == message.chatId }) {
                            room.messages.append(messageObject)
                        }
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func saveMessages(_ messages: [ChatMessage]) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

                try realm.write {
                    for message in messages {
                        let messageObject = ChatMessageObject.fromDomain(message)
                        realm.add(messageObject, update: .modified)

                        if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: message.roomId) {
                            if !room.messages.contains(where: { $0.chatId == message.chatId }) {
                                room.messages.append(messageObject)
                            }
                        }
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func fetchMessages(roomId: String) -> Observable<[ChatMessage]> {
        return Observable.create { [realmProvider] observer in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let realm = try realmProvider.realm()

                    guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                        DispatchQueue.main.async {
                            observer.onNext([])
                            observer.onCompleted()
                        }
                        return
                    }

                    let results = room.messages
                        .sorted(byKeyPath: "createdAt", ascending: true)

                    let chatMessages = Array(results.map { $0.toDomain() })

                    DispatchQueue.main.async {
                        observer.onNext(chatMessages)
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }

            return Disposables.create()
        }
    }

    func fetchRecentMessages(roomId: String, limit: Int = 50) -> Observable<[ChatMessage]> {
        return Observable.create { [realmProvider] observer in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let realm = try realmProvider.realm()

                    guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                        DispatchQueue.main.async {
                            observer.onNext([])
                            observer.onCompleted()
                        }
                        return
                    }

                    let results = room.messages
                        .sorted(byKeyPath: "createdAt", ascending: false)

                    let count = min(limit, results.count)
                    var messages: [ChatMessage] = []
                    messages.reserveCapacity(count)

                    for i in stride(from: count - 1, through: 0, by: -1) {
                        messages.append(results[i].toDomain())
                    }

                    DispatchQueue.main.async {
                        observer.onNext(messages)
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }

            return Disposables.create()
        }
    }

    func fetchOlderMessages(roomId: String, before: Date, limit: Int = 20) -> Observable<[ChatMessage]> {
        return Observable.create { [realmProvider] observer in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let realm = try realmProvider.realm()

                    guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                        DispatchQueue.main.async {
                            observer.onNext([])
                            observer.onCompleted()
                        }
                        return
                    }

                    let results = room.messages
                        .filter("createdAt < %@", before)
                        .sorted(byKeyPath: "createdAt", ascending: false)

                    let count = min(limit, results.count)
                    var messages: [ChatMessage] = []
                    messages.reserveCapacity(count)

                    for i in stride(from: count - 1, through: 0, by: -1) {
                        messages.append(results[i].toDomain())
                    }

                    DispatchQueue.main.async {
                        observer.onNext(messages)
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
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

            guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                return nil
            }

            return room.messages
                .sorted(byKeyPath: "createdAt", ascending: false)
                .first?
                .createdAt
        } catch {
            return nil
        }
    }

    func incrementUnreadCount(roomId: String) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

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
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

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
        return Observable.create { [realmProvider] observer in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let realm = try realmProvider.realm()

                    guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                        DispatchQueue.main.async {
                            observer.onNext([])
                            observer.onCompleted()
                        }
                        return
                    }

                    let results = room.messages
                        .filter("sendStatusRaw == %@", SendStatus.failed.rawValue)
                        .sorted(byKeyPath: "createdAt", ascending: true)

                    let chatMessages = Array(results.map { $0.toDomain() })

                    DispatchQueue.main.async {
                        observer.onNext(chatMessages)
                        observer.onCompleted()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer.onError(error)
                    }
                }
            }

            return Disposables.create()
        }
    }

    func deleteTempMessage(tempId: String) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()
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
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

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

    func deleteAllData() throws {
        let realm = try realmProvider.realm()

        try realm.write {
            realm.deleteAll()
        }

        Logger.storage.notice("All Realm data deleted")
    }

    func updateLastReadAt(roomId: String, date: Date) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        room.lastReadAt = date
                    }
                }

                completable(.completed)
            } catch {
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func getLastReadAt(roomId: String) -> Date? {
        do {
            let realm = try realmProvider.realm()
            let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId)
            return room?.lastReadAt
        } catch {
            return nil
        }
    }

    func getAllChatRoomIds() -> [String] {
        do {
            let realm = try realmProvider.realm()
            let rooms = realm.objects(ChatRoomObject.self)
            return Array(rooms.map { $0.roomId })
        } catch {
            return []
        }
    }

    func updateUnreadCount(roomId: String, count: Int) -> Completable {
        return Completable.create { [realmProvider] completable in
            do {
                let realm = try realmProvider.realm()

                if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                    try realm.write {
                        room.unreadCount = count
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
