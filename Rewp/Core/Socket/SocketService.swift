//
//  SocketService.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation
import SocketIO
import RxSwift
import RxCocoa
import OSLog

protocol SocketServiceProtocol {
    var isConnected: Observable<Bool> { get }
    var receivedMessage: Observable<ChatMessage> { get }
    var activeRoomId: String? { get }

    func connect(roomId: String)
    func disconnect()
}

final class SocketService: SocketServiceProtocol {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let keychainManager: KeychainManager

    private let isConnectedRelay = BehaviorRelay<Bool>(value: false)
    private let receivedMessageRelay = PublishRelay<ChatMessage>()

    private var currentUserId: String?
    private var currentRoomId: String?

    var activeRoomId: String? {
        return currentRoomId
    }

    var isConnected: Observable<Bool> {
        return isConnectedRelay.asObservable()
    }

    var receivedMessage: Observable<ChatMessage> {
        return receivedMessageRelay.asObservable()
    }

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    func connect(roomId: String) {
        guard socket == nil else {
            Logger.socket.notice("Socket already connected")
            return
        }

        guard let accessToken = try? keychainManager.loadAccessToken() else {
            Logger.socket.error("Failed to load access token for socket connection")
            return
        }

        currentUserId = extractUserId(from: accessToken)

        let baseURL = NetworkConfig.baseURL.replacingOccurrences(of: "/v1", with: "")
        guard let url = URL(string: baseURL) else {
            Logger.socket.error("Invalid socket URL")
            return
        }

        Logger.socket.debug("Socket URL - \(baseURL, privacy: .public)")

        manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .extraHeaders([
                    "Authorization": accessToken,
                    "SesacKey": NetworkConfig.rewpKey
                ])
            ]
        )

        let namespace = "/chats-\(roomId)"
        Logger.socket.debug("Socket namespace - \(namespace, privacy: .public)")

        socket = manager?.socket(forNamespace: namespace)
        setupEventHandlers()
        socket?.connect()

        currentRoomId = roomId
        Logger.socket.notice("Connecting to chat room - \(roomId, privacy: .public)")
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        currentRoomId = nil
        isConnectedRelay.accept(false)
        Logger.socket.notice("Socket disconnected")
    }

    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, _ in
            self?.isConnectedRelay.accept(true)
            Logger.socket.notice("Socket connected")
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, _ in
            self?.isConnectedRelay.accept(false)
            Logger.socket.notice("Socket disconnected")
        }

        socket?.on(clientEvent: .error) { data, _ in
            if !data.isEmpty {
                Logger.socket.error("Socket error - \(data)")
            } else {
                Logger.socket.error("Socket error - Unknown error")
            }
        }

        socket?.on(clientEvent: .reconnect) { data, _ in
            Logger.socket.notice("Socket reconnected")
        }

        socket?.on("chat") { [weak self] data, _ in
            guard let self = self else { return }

            guard let messageData = data.first as? [String: Any] else {
                Logger.socket.error("Failed to parse socket message data")
                return
            }

            if let message = self.parseMessage(from: messageData) {
                self.receivedMessageRelay.accept(message)
                Logger.socket.notice("Message received - sender: \(message.senderNickname, privacy: .public)")
            } else {
                Logger.socket.error("Failed to parse message from socket data")
            }
        }
    }

    private func parseMessage(from data: [String: Any]) -> ChatMessage? {
        guard let chatId = data["chat_id"] as? String,
              let roomId = data["room_id"] as? String,
              let content = data["content"] as? String,
              let sender = data["sender"] as? [String: Any],
              let senderId = sender["user_id"] as? String,
              let senderNickname = sender["nick"] as? String,
              let createdAtString = data["createdAt"] as? String else {
            return nil
        }

        let senderProfileImage = sender["profileImage"] as? String
        let createdAt = parseDate(from: createdAtString) ?? Date()
        let isFromMe = senderId == currentUserId

        return ChatMessage(
            chatId: chatId,
            roomId: roomId,
            content: content,
            senderId: senderId,
            senderNickname: senderNickname,
            senderProfileImage: senderProfileImage,
            createdAt: createdAt,
            isFromMe: isFromMe
        )
    }

    private func parseDate(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }

    private func extractUserId(from token: String) -> String? {
        let segments = token.components(separatedBy: ".")
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
