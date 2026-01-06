//
//  VideoRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation
import Alamofire

enum VideoRouter {
    case getVideos(next: String?, limit: Int)
    case getStream(videoId: String)
    case likeVideo(videoId: String, likeStatus: Bool)
}

extension VideoRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .getVideos:
            return "/v1/videos"
        case .getStream(let videoId):
            return "/v1/videos/\(videoId)/stream"
        case .likeVideo(let videoId, _):
            return "/v1/videos/\(videoId)/like"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getVideos, .getStream:
            return .get
        case .likeVideo:
            return .post
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
        case .getVideos, .getStream:
            return nil
        case .likeVideo(_, let likeStatus):
            return LikeVideoRequest(like_status: likeStatus)
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .getVideos(let next, let limit):
            var params: [String: String] = ["limit": "\(limit)"]
            if let next = next {
                params["next"] = next
            }
            return params
        case .getStream, .likeVideo:
            return nil
        }
    }
}
