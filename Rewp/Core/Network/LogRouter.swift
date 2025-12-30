//
//  LogRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/27/25.
//

import Foundation
import Moya

enum LogRouter {
    case getLogs
}

extension LogRouter: TargetType {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        return "/v1/log"
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "SesacKey": NetworkConfig.rewpKey
        ]
    }
}
