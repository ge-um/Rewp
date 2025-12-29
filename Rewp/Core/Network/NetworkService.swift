//
//  NetworkService.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import Foundation
import Moya
import RxSwift

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ target: TargetType) -> Single<T>
    func requestEmpty(_ target: TargetType) -> Single<Void>
}

final class NetworkService: NetworkServiceProtocol {
    private let provider: MoyaProvider<MultiTarget>

    init() {
        self.provider = MoyaProvider<MultiTarget>()
    }

    func request<T: Decodable>(_ target: TargetType) -> Single<T> {
        return provider.rx.request(MultiTarget(target))
            .flatMap { response -> Single<T> in
                if (200...299).contains(response.statusCode) {
                    do {
                        let data = try response.map(T.self)
                        return .just(data)
                    } catch {
                        return .error(NetworkError.decodingError)
                    }
                } else if response.statusCode == 419 {
                    return .error(AuthError.tokenExpired)
                } else if response.statusCode == 401 || response.statusCode == 403 {
                    return .error(AuthError.notAuthenticated)
                } else {
                    if let errorResponse = try? response.map(ErrorResponse.self) {
                        return .error(NetworkError.serverError(message: errorResponse.message))
                    } else {
                        return .error(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다."))
                    }
                }
            }
    }

    func requestEmpty(_ target: TargetType) -> Single<Void> {
        return provider.rx.request(MultiTarget(target))
            .flatMap { response -> Single<Void> in
                if (200...299).contains(response.statusCode) {
                    return .just(())
                } else if response.statusCode == 419 {
                    return .error(AuthError.tokenExpired)
                } else if response.statusCode == 401 || response.statusCode == 403 {
                    return .error(AuthError.notAuthenticated)
                } else {
                    if let errorResponse = try? response.map(ErrorResponse.self) {
                        return .error(NetworkError.serverError(message: errorResponse.message))
                    } else {
                        return .error(NetworkError.serverError(message: "알 수 없는 서버 오류가 발생했습니다."))
                    }
                }
            }
    }

}
