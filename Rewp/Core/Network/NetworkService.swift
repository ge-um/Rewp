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
            .filterSuccessfulStatusCodes()
            .map(T.self)
    }
}
