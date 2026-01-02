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
    func fetchHotEstates() -> Single<[EstateDTO]>
    func fetchTodayTopics() -> Single<[TopicDTO]>
    func fetchEstateDetail(estateId: String) -> Single<EstateDetailResponse>
    func fetchSimilarEstates() -> Single<[EstateDTO]>
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

    func fetchHotEstates() -> Single<[EstateDTO]> {
        return authService.authenticatedRequest(EstateRouter.hotEstates)
            .map { (response: TodayEstatesResponse) in
                return response.data
            }
    }

    func fetchTodayTopics() -> Single<[TopicDTO]> {
        return authService.authenticatedRequest(EstateRouter.todayTopic)
            .map { (response: TodayTopicsResponse) in
                return response.data
            }
    }

    func fetchEstateDetail(estateId: String) -> Single<EstateDetailResponse> {
        return authService.authenticatedRequest(EstateRouter.estateDetail(estateId: estateId))
    }

    func fetchSimilarEstates() -> Single<[EstateDTO]> {
        return authService.authenticatedRequest(EstateRouter.similarEstates)
            .map { (response: TodayEstatesResponse) in
                return response.data
            }
    }
}
