//
//  FeedPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

class FeedPresenter {
    private let estateRepository: EstateRepository
    private let bannerRepository: BannerRepository
    private let recentlyViewedRepository: RecentlyViewedEstateRepository
    private let disposeBag = DisposeBag()

    init(
        estateRepository: EstateRepository,
        bannerRepository: BannerRepository,
        recentlyViewedRepository: RecentlyViewedEstateRepository
    ) {
        self.estateRepository = estateRepository
        self.bannerRepository = bannerRepository
        self.recentlyViewedRepository = recentlyViewedRepository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let topicTapped: Observable<TopicItem>
        let bannerTapped: Observable<String>
        let hotEstateTapped: Observable<String>
        let newsAdTapped: Observable<(String, String)>
        let recentlyViewedEstateTapped: Observable<String>
    }

    struct Output {
        let banners: Driver<[BannerItem]>
        let hotEstates: Driver<[HotEstateItem]>
        let topics: Driver<[TopicItem]>
        let newsAds: Driver<[BannerAdItem]>
        let openTopicLink: Driver<String>
        let navigateToDetail: Driver<String>
        let openAttendanceWebView: Driver<String>
        let recentlyViewedEstates: Driver<[RecentlyViewedEstateItem]>
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

        let newsAds = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.bannerRepository.fetchMainBanners()
                    .map { dtos in dtos.map { $0.toBannerAdItem() } }
                    .asObservable()
                    .catch { error in
                        Logger.network.error("Failed to fetch banners")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        let openAttendanceWebView = input.newsAdTapped
            .filter { $0.0 == "WEBVIEW" }
            .map { $0.1 }
            .asDriver(onErrorDriveWith: .empty())

        let openTopicLink = input.topicTapped
            .map { $0.link }
            .asDriver(onErrorDriveWith: .empty())

        let recentlyViewedEstates = input.viewWillAppear
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.recentlyViewedRepository.fetchRecentlyViewedEstates()
                    .catch { error in
                        Logger.storage.error("Failed to fetch recently viewed estates: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToDetail = Observable.merge(
            input.bannerTapped,
            input.hotEstateTapped,
            input.recentlyViewedEstateTapped
        )
        .asDriver(onErrorDriveWith: .empty())

        return Output(
            banners: banners,
            hotEstates: hotEstates,
            topics: topics,
            newsAds: newsAds,
            openTopicLink: openTopicLink,
            navigateToDetail: navigateToDetail,
            openAttendanceWebView: openAttendanceWebView,
            recentlyViewedEstates: recentlyViewedEstates
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
