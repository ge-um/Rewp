//
//  SettingsPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SettingsPresenter {
    private let authService: AuthServiceProtocol
    private let disposeBag = DisposeBag()

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    struct Input {
        let logoutTapped: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let shouldLogout: Driver<Void>
        let logoutError: Driver<String>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let logoutRelay = PublishRelay<Void>()
        let errorRelay = PublishRelay<String>()

        input.logoutTapped
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, _ in
                owner.authService.logout()
                    .asObservable()
                    .catch { error in
                        loadingRelay.accept(false)
                        errorRelay.accept(error.localizedDescription)
                        return Observable.empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                loadingRelay.accept(false)
                logoutRelay.accept(())
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            shouldLogout: logoutRelay.asDriver(onErrorDriveWith: Driver.empty()),
            logoutError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류")
        )
    }
}
