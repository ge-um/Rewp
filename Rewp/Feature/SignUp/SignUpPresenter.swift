//
//  SignUpPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SignUpPresenter {
    private let userRepository: UserRepository
    private let disposeBag = DisposeBag()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    struct Input {
        let emailText: Observable<String>
        let passwordText: Observable<String>
        let nicknameText: Observable<String>
        let phoneText: Observable<String>
        let introductionText: Observable<String>
        let signUpButtonTapped: Observable<Void>
        let emailEditingDidEnd: Observable<Void>
        let passwordEditingDidBegin: Observable<Void>
        let nicknameEditingDidBegin: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let signUpSuccess: Driver<Void>
        let signUpError: Driver<String>
        let emailValidationMessage: Driver<String?>
        let emailValidationState: Driver<ValidationState>
        let passwordValidationError: Driver<String?>
        let nicknameValidationError: Driver<String?>
        let isSignUpButtonEnabled: Driver<Bool>
    }

    enum ValidationState {
        case none
        case validating
        case valid
        case invalid
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<Void>()
        let errorRelay = PublishRelay<String>()
        let emailValidationMessageRelay = PublishRelay<String?>()
        let emailValidationStateRelay = BehaviorRelay<ValidationState>(value: .none)
        let passwordValidationErrorRelay = PublishRelay<String?>()
        let nicknameValidationErrorRelay = PublishRelay<String?>()

        return Output(
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            signUpSuccess: successRelay.asDriver(onErrorDriveWith: .empty()),
            signUpError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류"),
            emailValidationMessage: emailValidationMessageRelay.asDriver(onErrorJustReturn: nil),
            emailValidationState: emailValidationStateRelay.asDriver(),
            passwordValidationError: passwordValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            nicknameValidationError: nicknameValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            isSignUpButtonEnabled: .just(false)
        )
    }
}
