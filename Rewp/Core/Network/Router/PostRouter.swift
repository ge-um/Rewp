//
//  PostRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import Alamofire

struct CreatePostRequest: Codable {
    let category: String
    let title: String
    let content: String
    let latitude: Double
    let longitude: Double
    let files: [String]
}

enum PostRouter {
    case geolocationPosts(longitude: Double?, latitude: Double?, limit: String?, product_id: String?, next_cursor: String?)
    case postDetail(postId: String)
    case createPost(category: String, title: String, content: String, latitude: Double, longitude: Double, files: [String])
    case deletePost(postId: String)
    case toggleLike(postId: String, likeStatus: Bool)
    case createComment(postId: String, content: String, parentCommentId: String?)
    case updateComment(postId: String, commentId: String, content: String)
    case deleteComment(postId: String, commentId: String)
}

extension PostRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .geolocationPosts:
            return "/posts/geolocation"
        case .postDetail(let postId):
            return "/posts/\(postId)"
        case .createPost:
            return "/posts"
        case .deletePost(let postId):
            return "/posts/\(postId)"
        case .toggleLike(let postId, _):
            return "/posts/\(postId)/like"
        case .createComment(let postId, _, _):
            return "/posts/\(postId)/comments"
        case .updateComment(let postId, let commentId, _):
            return "/posts/\(postId)/comments/\(commentId)"
        case .deleteComment(let postId, let commentId):
            return "/posts/\(postId)/comments/\(commentId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .geolocationPosts, .postDetail:
            return .get
        case .createPost, .toggleLike, .createComment:
            return .post
        case .updateComment:
            return .put
        case .deletePost, .deleteComment:
            return .delete
        }
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }

    var body: Encodable? {
        switch self {
        case .geolocationPosts, .postDetail, .deletePost:
            return nil
        case .createPost(let category, let title, let content, let latitude, let longitude, let files):
            return CreatePostRequest(
                category: category,
                title: title,
                content: content,
                latitude: latitude,
                longitude: longitude,
                files: files
            )
        case .toggleLike(_, let likeStatus):
            return ["like_status": likeStatus]
        case .createComment(_, let content, let parentCommentId):
            var params: [String: String] = ["content": content]
            if let parentCommentId = parentCommentId {
                params["parent_comment_id"] = parentCommentId
            }
            return params
        case .updateComment(_, _, let content):
            return ["content": content]
        case .deleteComment:
            return nil
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .geolocationPosts(let longitude, let latitude, let limit, let product_id, let next_cursor):
            var params: [String: String] = [:]
            if let longitude = longitude {
                params["longitude"] = "\(longitude)"
            }
            if let latitude = latitude {
                params["latitude"] = "\(latitude)"
            }
            if let limit = limit {
                params["limit"] = limit
            }
            if let product_id = product_id {
                params["product_id"] = product_id
            }
            if let next_cursor = next_cursor {
                params["next_cursor"] = next_cursor
            }
            return params
        case .postDetail, .createPost, .deletePost, .toggleLike, .createComment, .updateComment, .deleteComment:
            return nil
        }
    }
}
