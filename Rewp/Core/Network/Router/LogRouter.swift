//
//  LogRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/27/25.
//

import Foundation
import Alamofire

enum LogRouter {
    case getLogs
}

extension LogRouter: APIRouter {
    var baseURL: URL {
        return URL(string: NetworkConfig.baseURL)!
    }

    var path: String {
        return "/log"
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
}
