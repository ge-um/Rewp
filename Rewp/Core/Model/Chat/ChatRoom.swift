//
//  ChatRoom.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import Foundation

struct ChatRoom {
    let roomId: String
    let participantId: String
    let participantName: String
    let participantProfileImage: String?
    let lastMessage: String
    let lastMessageDate: Date
    let unreadCount: Int

    var relativeTime: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: lastMessageDate, to: now)

        if let day = components.day, day >= 1 {
            if day == 1 {
                return "어제"
            } else if day < 7 {
                return "\(day)일 전"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M월 d일"
                return formatter.string(from: lastMessageDate)
            }
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)분 전"
        } else {
            return "방금"
        }
    }
}

extension ChatRoom {
    static func mockChatRooms() -> [ChatRoom] {
        let now = Date()
        let calendar = Calendar.current

        return [
            ChatRoom(
                roomId: "room-1",
                participantId: "user-1",
                participantName: "김부동산",
                participantProfileImage: nil,
                lastMessage: "네, 토요일 오후 2시에 가능합니다.",
                lastMessageDate: calendar.date(byAdding: .minute, value: -5, to: now)!,
                unreadCount: 2
            ),
            ChatRoom(
                roomId: "room-2",
                participantId: "user-2",
                participantName: "이중개사",
                participantProfileImage: nil,
                lastMessage: "매물 정보 보내드렸습니다. 확인해주세요!",
                lastMessageDate: calendar.date(byAdding: .hour, value: -2, to: now)!,
                unreadCount: 0
            ),
            ChatRoom(
                roomId: "room-3",
                participantId: "user-3",
                participantName: "박공인",
                participantProfileImage: nil,
                lastMessage: "감사합니다. 좋은 하루 되세요!",
                lastMessageDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                unreadCount: 0
            )
        ]
    }
}
