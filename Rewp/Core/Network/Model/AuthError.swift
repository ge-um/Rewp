//
//  AuthError.swift
//  Rewp
//
//  Created by 금가경 on 12/29/25.
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
    case invalidToken
    case tokenExpired
    case refreshFailed
    case unknown

    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "인증되지 않았습니다"
        case .invalidToken:
            return "유효하지 않은 토큰입니다"
        case .tokenExpired:
            return "토큰이 만료되었습니다"
        case .refreshFailed:
            return "토큰 갱신에 실패했습니다"
        case .unknown:
            return "알 수 없는 인증 오류가 발생했습니다"
        }
    }
}
