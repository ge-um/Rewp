//
//  LogRepository.swift
//  Rewp
//
//  Created by 금가경 on 12/27/25.
//

import Foundation
import RxSwift

protocol LogRepository {
    func getLogs() -> Single<LogResponse>
}

final class LogRepositoryImpl: LogRepository {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func getLogs() -> Single<LogResponse> {
        return networkService.request(LogRouter.getLogs)
    }
}
