//
//  KakaoRouter.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import Foundation
import Alamofire

enum KakaoRouter {
    case searchKeyword(query: String, x: String?, y: String?, radius: Int?, size: Int)
}

extension KakaoRouter: APIRouter {
    var baseURL: URL {
        return URL(string: "https://dapi.kakao.com")!
    }

    var path: String {
        switch self {
        case .searchKeyword:
            return "/v2/local/search/keyword.json"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var headers: HTTPHeaders? {
        return [
            "Authorization": "KakaoAK \(NetworkConfig.kakaoRestAPIKey)"
        ]
    }

    var body: Encodable? {
        return nil
    }

    var queryParameters: [String: String]? {
        switch self {
        case .searchKeyword(let query, let x, let y, let radius, let size):
            var params: [String: String] = [
                "query": query,
                "size": String(size)
            ]

            if let x = x {
                params["x"] = x
            }
            if let y = y {
                params["y"] = y
            }
            if let radius = radius {
                params["radius"] = String(radius)
            }

            return params
        }
    }
}
