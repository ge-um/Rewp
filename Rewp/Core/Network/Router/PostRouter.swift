//
//  PostRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import Alamofire

enum PostRouter {
    case geolocationPosts(longitude: Double?, latitude: Double?, limit: String?, product_id: String?)
    case postDetail(postId: String)
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
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }

    var body: Encodable? {
        return nil
    }

    var queryParameters: [String: String]? {
        switch self {
        case .geolocationPosts(let longitude, let latitude, let limit, let product_id):
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
            return params
        case .postDetail:
            return nil
        }
    }
}
