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
    var queryParameters: [String: String]? { get }
}

extension APIRouter {
    var body: Encodable? { nil }
    var queryParameters: [String: String]? { nil }

    func asURLRequest() throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)

        if let queryParameters = queryParameters {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }

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
