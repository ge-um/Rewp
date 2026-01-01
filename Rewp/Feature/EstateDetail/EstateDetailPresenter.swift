//
//  EstateDetailPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import Foundation
import RxSwift
import RxCocoa

final class EstateDetailPresenter {
    private let estateId: String
    private let disposeBag = DisposeBag()

    init(estateId: String) {
        self.estateId = estateId
    }

    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
    }

    func transform(input: Input) -> Output {
        return Output()
    }
}
