//
//  FeedPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import Foundation
import RxSwift
import RxCocoa

class FeedPresenter {
    private let estateRepository: EstateRepository
    private let disposeBag = DisposeBag()

    init(estateRepository: EstateRepository) {
        self.estateRepository = estateRepository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let tabSelected: Observable<Int>
    }

    struct Output {
        let banners: Driver<[BannerItem]>
        let hotEstates: Driver<[HotEstateItem]>
        let navigateToSettings: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let banners = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                return owner.fetchBanners()
            }
            .asDriver(onErrorJustReturn: [])

        let hotEstates = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                return owner.fetchHotEstates()
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToSettings = input.tabSelected
            .filter { $0 == 2 }
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            banners: banners,
            hotEstates: hotEstates,
            navigateToSettings: navigateToSettings
        )
    }

    private func fetchBanners() -> Observable<[BannerItem]> {
        return estateRepository.fetchTodayEstates()
            .asObservable()
            .map { estates in
                estates.map { $0.toBannerItem() }
            }
    }

    private func fetchHotEstates() -> Observable<[HotEstateItem]> {
        return estateRepository.fetchHotEstates()
            .asObservable()
            .map { estates in
                estates.map { $0.toHotEstateItem() }
            }
    }
}
