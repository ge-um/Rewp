//
//  BannerRepository.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation
import RxSwift

protocol BannerRepository {
    func fetchMainBanners() -> Single<[BannerDTO]>
}

final class BannerRepositoryImpl: BannerRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func fetchMainBanners() -> Single<[BannerDTO]> {
        return authService.authenticatedRequest(BannerRouter.mainBanners)
            .map { (response: MainBannersResponse) in
                return response.data
            }
    }
}
