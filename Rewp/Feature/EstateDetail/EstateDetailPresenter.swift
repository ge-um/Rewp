//
//  EstateDetailPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class EstateDetailPresenter {
    private let estateId: String
    private let repository: EstateRepository
    private let disposeBag = DisposeBag()

    init(estateId: String, repository: EstateRepository) {
        self.estateId = estateId
        self.repository = repository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let similarEstateTapped: Observable<String>
        let likeTapped: Observable<Void>
    }

    struct Output {
        let estateDetail: Driver<EstateDetail>
        let similarEstates: Driver<[SimilarEstateItem]>
        let navigateToDetail: Driver<String>
        let error: Driver<String>
        let isLoading: Driver<Bool>
        let likeStatus: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let errorRelay = PublishRelay<String>()
        let loadingRelay = PublishRelay<Bool>()
        let likeStatusRelay = BehaviorRelay<Bool>(value: false)

        let estateDetail = input.viewDidLoad
            .do(onNext: {
                loadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<EstateDetail> in
                guard let self = self else {
                    Logger.ui.error("Self is nil in flatMapLatest")
                    return .empty()
                }
                return self.repository.fetchEstateDetail(estateId: self.estateId)
                    .map { response in
                        response.toEstateDetail()
                    }
                    .asObservable()
                    .do(onNext: { detail in
                        loadingRelay.accept(false)
                        likeStatusRelay.accept(detail.isLiked)
                    })
                    .catch { error in
                        Logger.ui.error("fetchEstateDetail error: \(error.localizedDescription)")
                        loadingRelay.accept(false)
                        errorRelay.accept(error.localizedDescription)
                        return .empty()
                    }
            }
            .asDriver(onErrorDriveWith: .empty())

        let similarEstates = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[SimilarEstateItem]> in
                guard let self = self else { return .empty() }
                return self.repository.fetchSimilarEstates()
                    .map { estateList in
                        estateList.map { $0.toSimilarEstateItem() }
                    }
                    .asObservable()
                    .catch { error in
                        Logger.ui.error("fetchSimilarEstates error: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToDetail = input.similarEstateTapped
            .asDriver(onErrorDriveWith: .empty())

        input.likeTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let currentStatus = likeStatusRelay.value
                let newStatus = !currentStatus
                likeStatusRelay.accept(newStatus)

                owner.repository.likeEstate(estateId: owner.estateId, likeStatus: newStatus)
                    .subscribe(onSuccess: { _ in
                        Logger.ui.notice("Like status updated - estateId: \(owner.estateId), status: \(newStatus)")
                    }, onFailure: { error in
                        Logger.ui.error("Like estate failed - \(error.localizedDescription)")
                        likeStatusRelay.accept(currentStatus)
                        errorRelay.accept("좋아요 처리에 실패했습니다.")
                    })
                    .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        return Output(
            estateDetail: estateDetail,
            similarEstates: similarEstates,
            navigateToDetail: navigateToDetail,
            error: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다."),
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            likeStatus: likeStatusRelay.asDriver()
        )
    }
}
