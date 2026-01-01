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
        let topicTapped: Observable<TopicItem>
        let bannerTapped: Observable<String>
        let hotEstateTapped: Observable<String>
    }

    struct Output {
        let banners: Driver<[BannerItem]>
        let hotEstates: Driver<[HotEstateItem]>
        let topics: Driver<[TopicItem]>
        let openTopicLink: Driver<String>
        let navigateToSettings: Driver<Void>
        let navigateToDetail: Driver<String>
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

        let topics = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                return owner.fetchTopics()
            }
            .asDriver(onErrorJustReturn: [])

        let openTopicLink = input.topicTapped
            .map { $0.link }
            .asDriver(onErrorDriveWith: .empty())

        let navigateToSettings = input.tabSelected
            .filter { $0 == 2 }
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        let navigateToDetail = Observable.merge(
            input.bannerTapped,
            input.hotEstateTapped
        )
        .asDriver(onErrorDriveWith: .empty())

        return Output(
            banners: banners,
            hotEstates: hotEstates,
            topics: topics,
            openTopicLink: openTopicLink,
            navigateToSettings: navigateToSettings,
            navigateToDetail: navigateToDetail
        )
    }

    private func fetchBanners() -> Observable<[BannerItem]> {
        return estateRepository.fetchTodayEstates()
            .asObservable()
            .flatMap { estates -> Observable<[BannerItem]> in
                if estates.isEmpty {
                    return .just([])
                }

                return Observable.from(estates)
                    .concatMap { $0.toBannerItem().asObservable() }
                    .toArray()
                    .asObservable()
            }
    }

    private func fetchHotEstates() -> Observable<[HotEstateItem]> {
        return estateRepository.fetchHotEstates()
            .asObservable()
            .map { estates in
                estates.map { $0.toHotEstateItem() }
            }
    }

    private func fetchTopics() -> Observable<[TopicItem]> {
        return estateRepository.fetchTodayTopics()
            .asObservable()
            .map { topics in
                topics.map { $0.toTopicItem() }
            }
    }
}
