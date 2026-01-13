//
//  PostDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

struct PostsResponse: Codable {
    let data: [PostDTO]
    let next_cursor: String
}

struct LikeResponse: Codable {
    let like_status: Bool
}

struct PostDTO: Codable {
    let post_id: String
    let category: String
    let title: String
    let content: String
    let geolocation: GeolocationDTO
    let creator: PostCreatorDTO
    let files: [String]
    let is_like: Bool
    let like_count: Int
    let comments: [PostCommentDTO]?
    let createdAt: String
    let updatedAt: String
}

struct GeolocationDTO: Codable {
    let longitude: Double
    let latitude: Double
}

struct PostCreatorDTO: Codable {
    let user_id: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}

struct PostCommentDTO: Codable {
    let comment_id: String
    let content: String
    let createdAt: String
    let creator: PostCreatorDTO
    let replies: [PostReplyDTO]?
}

struct PostReplyDTO: Codable {
    let comment_id: String
    let content: String
    let createdAt: String
    let creator: PostCreatorDTO
}

extension PostDTO {
    func toDomain() -> Post {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdDate = formatter.date(from: createdAt) ?? Date()

        let imageURLs = files.compactMap { urlString -> String? in
            guard !urlString.isEmpty else { return nil }
            return "\(NetworkConfig.baseURL)\(urlString)"
        }

        let profileImageURL: String? = {
            guard let profileImage = creator.profileImage, !profileImage.isEmpty else {
                return nil
            }
            return "\(NetworkConfig.baseURL)\(profileImage)"
        }()

        let domainComments = (comments ?? []).map { commentDTO in
            commentDTO.toDomain()
        }

        let postCategory = PostCategory(from: category)

        return Post(
            postId: post_id,
            title: title,
            content: content,
            category: postCategory,
            creatorId: creator.user_id,
            creatorNickname: creator.nick,
            creatorProfileImage: profileImageURL,
            imageURLs: imageURLs,
            likesCount: like_count,
            commentsCount: comments?.count ?? 0,
            createdAt: createdDate,
            isLiked: is_like,
            comments: domainComments
        )
    }
}

extension PostCommentDTO {
    func toDomain() -> Comment {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdDate = formatter.date(from: createdAt) ?? Date()

        let profileImageURL: String? = {
            guard let profileImage = creator.profileImage, !profileImage.isEmpty else {
                return nil
            }
            return "\(NetworkConfig.baseURL)\(profileImage)"
        }()

        let domainReplies = (replies ?? []).map { replyDTO in
            replyDTO.toDomain()
        }

        return Comment(
            commentId: comment_id,
            content: content,
            creatorId: creator.user_id,
            creatorNickname: creator.nick,
            creatorProfileImage: profileImageURL,
            createdAt: createdDate,
            replies: domainReplies
        )
    }
}

extension PostReplyDTO {
    func toDomain() -> Reply {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdDate = formatter.date(from: createdAt) ?? Date()

        let profileImageURL: String? = {
            guard let profileImage = creator.profileImage, !profileImage.isEmpty else {
                return nil
            }
            return "\(NetworkConfig.baseURL)\(profileImage)"
        }()

        return Reply(
            replyId: comment_id,
            content: content,
            creatorId: creator.user_id,
            creatorNickname: creator.nick,
            creatorProfileImage: profileImageURL,
            createdAt: createdDate
        )
    }
}
