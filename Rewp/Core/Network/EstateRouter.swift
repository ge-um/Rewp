//
//  EstateRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import Moya

enum EstateRouter {
    case todayEstates
}

extension EstateRouter: TargetType {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        switch self {
        case .todayEstates:
            return "/estates/today-estates"
        }
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
