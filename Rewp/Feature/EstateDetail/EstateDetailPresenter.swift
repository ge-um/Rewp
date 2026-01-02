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
    }

    struct Output {
        let estateDetail: Driver<EstateDetail>
        let similarEstates: Driver<[SimilarEstateItem]>
        let error: Driver<String>
        let isLoading: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let errorRelay = PublishRelay<String>()
        let loadingRelay = PublishRelay<Bool>()

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
                    .do(onNext: { _ in
                        loadingRelay.accept(false)
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

        return Output(
            estateDetail: estateDetail,
            similarEstates: similarEstates,
            error: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다."),
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false)
        )
    }
}
