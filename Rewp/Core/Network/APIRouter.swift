//
//  APIRouter.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import Alamofire

protocol APIRouter: URLRequestConvertible {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var body: Encodable? { get }
}

extension APIRouter {
    var body: Encodable? { nil }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.headers = headers ?? [:]

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.headers.add(.contentType("application/json"))
        }

        return request
    }
}
