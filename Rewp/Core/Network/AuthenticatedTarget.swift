//
//  AuthenticatedTarget.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation
import Moya

struct AuthenticatedTarget: TargetType {
    let base: TargetType
    let accessToken: String

    var baseURL: URL {
        base.baseURL
    }

    var path: String {
        base.path
    }

    var method: Moya.Method {
        base.method
    }

    var task: Task {
        base.task
    }

    var sampleData: Data {
        base.sampleData
    }

    var headers: [String: String]? {
        var headers = base.headers ?? [:]
        headers["Authorization"] = accessToken
        return headers
    }
}
