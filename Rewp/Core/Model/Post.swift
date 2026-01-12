//
//  Post.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

struct Post {
    let postId: String
    let title: String
    let content: String
    let creatorId: String
    let creatorNickname: String
    let creatorProfileImage: String?
    let imageURLs: [String]
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Date
    let isLiked: Bool
    let comments: [Comment]

    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        }
    }

    var thumbnailURL: String? {
        return imageURLs.first
    }
}

struct Comment {
    let commentId: String
    let content: String
    let creatorId: String
    let creatorNickname: String
    let creatorProfileImage: String?
    let createdAt: Date
    let replies: [Reply]

    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        }
    }
}

struct Reply {
    let replyId: String
    let content: String
    let creatorId: String
    let creatorNickname: String
    let creatorProfileImage: String?
    let createdAt: Date

    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "방금 전"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        }
    }
}
