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
}

final class NetworkService: NetworkServiceProtocol {
    private let provider: MoyaProvider<MultiTarget>

    init(provider: MoyaProvider<MultiTarget> = MoyaProvider<MultiTarget>()) {
        self.provider = provider
    }

    func request<T: Decodable>(_ target: TargetType) -> Single<T> {
        return provider.rx
            .request(MultiTarget(target))
            .flatMap { response -> Single<T> in
                if (200...299).contains(response.statusCode) {
                    do {
                        let data = try response.map(T.self)
                        return .just(data)
                    } catch {
                        return .error(NetworkError.decodingError)
                    }
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
