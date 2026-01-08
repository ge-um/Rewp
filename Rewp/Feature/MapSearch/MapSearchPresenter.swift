//
//  MapSearchPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation
import RxSwift
import RxCocoa

final class MapSearchPresenter {
    private let estateRepository: EstateRepository
    private let disposeBag = DisposeBag()

    init(estateRepository: EstateRepository) {
        self.estateRepository = estateRepository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let estates: Driver<[EstateDTO]>
        let error: Driver<String>
    }

    func transform(input: Input) -> Output {
        let estatesRelay = PublishRelay<[EstateDTO]>()
        let errorRelay = PublishRelay<String>()

        input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.estateRepository.fetchEstatesByLocation(
                    longitude: nil,
                    latitude: nil,
                    maxDistance: nil,
                    category: nil
                )
            }
            .subscribe(
                onNext: { estates in
                    estatesRelay.accept(estates)
                },
                onError: { error in
                    errorRelay.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)

        return Output(
            estates: estatesRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: "")
        )
    }
}
