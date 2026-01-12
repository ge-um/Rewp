//
//  CommunityPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class CommunityPresenter {
    private let postRepository: PostRepository
    private let locationManager: LocationManager
    private let disposeBag = DisposeBag()

    init(postRepository: PostRepository, locationManager: LocationManager = .shared) {
        self.postRepository = postRepository
        self.locationManager = locationManager
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let refreshTriggered: Observable<Void>
        let postSelected: Observable<String>
    }

    struct Output {
        let posts: Driver<[Post]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let navigateToDetail: Driver<String>
    }

    func transform(input: Input) -> Output {
        let postsRelay = PublishRelay<[Post]>()
        let isLoadingRelay = PublishRelay<Bool>()
        let errorRelay = PublishRelay<String>()
        let navigateToDetailRelay = PublishRelay<String>()

        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            input.viewWillAppear.skip(1),
            input.refreshTriggered
        )

        loadTrigger
            .withUnretained(self)
            .do(onNext: { owner, _ in
                isLoadingRelay.accept(true)
            })
            .flatMapLatest { owner, _ -> Observable<[PostDTO]> in
                return owner.locationManager.currentLocation
                    .take(1)
                    .timeout(.seconds(2), scheduler: MainScheduler.instance)
                    .map { location -> (Double?, Double?) in
                        (location.coordinate.longitude, location.coordinate.latitude)
                    }
                    .catchAndReturn((nil, nil))
                    .flatMap { longitude, latitude in
                        owner.postRepository
                            .fetchPostsByLocation(
                                longitude: longitude,
                                latitude: latitude,
                                limit: "50",
                                productId: NetworkConfig.productId
                            )
                            .asObservable()
                            .catch { error in
                                Logger.community.error("Failed to fetch posts - \(error.localizedDescription)")
                                isLoadingRelay.accept(false)
                                errorRelay.accept("게시글을 불러올 수 없습니다")
                                return .empty()
                            }
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, postDTOs in
                isLoadingRelay.accept(false)
                let posts = postDTOs.map { $0.toDomain() }
                postsRelay.accept(posts)
            })
            .disposed(by: disposeBag)

        input.postSelected
            .bind(to: navigateToDetailRelay)
            .disposed(by: disposeBag)

        return Output(
            posts: postsRelay.asDriver(onErrorDriveWith: .empty()),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            navigateToDetail: navigateToDetailRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
