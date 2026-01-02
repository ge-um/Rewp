//
//  NetworkError.swift
//  Rewp
//
//  Created by 금가경 on 12/27/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case serverError(message: String)
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .decodingError:
            return "디코딩 에러가 발생했습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
