//
//  EstateRepository.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import RxSwift

protocol EstateRepository {
    func fetchTodayEstates() -> Single<[EstateDTO]>
}

final class EstateRepositoryImpl: EstateRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func fetchTodayEstates() -> Single<[EstateDTO]> {
        return authService.authenticatedRequest(EstateRouter.todayEstates)
            .map { (response: TodayEstatesResponse) in
                return response.data
            }
    }
}
