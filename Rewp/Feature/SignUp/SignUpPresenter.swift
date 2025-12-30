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
    private let container: AppContainer
    private let disposeBag = DisposeBag()

    init(userRepository: UserRepository, container: AppContainer) {
        self.userRepository = userRepository
        self.container = container
    }

    struct Input {
        let emailText: Observable<String>
        let passwordText: Observable<String>
        let nicknameText: Observable<String>
        let phoneText: Observable<String>
        let introductionText: Observable<String>
        let signUpButtonTapped: Observable<Void>
        let emailEditingDidBegin: Observable<Void>
        let passwordEditingDidBegin: Observable<Void>
        let nicknameEditingDidBegin: Observable<Void>
        let passwordToggleTapped: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let signUpSuccess: Driver<(nickname: String, email: String)>
        let signUpError: Driver<String>
        let emailValidationError: Driver<String?>
        let emailCheckState: Driver<EmailCheckState>
        let passwordValidationError: Driver<String?>
        let nicknameValidationError: Driver<String?>
        let isSignUpButtonEnabled: Driver<Bool>
        let isPasswordVisible: Driver<Bool>
    }

    enum EmailCheckState {
        case none
        case available
        case unavailable
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<(nickname: String, email: String)>()
        let errorRelay = PublishRelay<String>()
        let emailValidationErrorRelay = PublishRelay<String?>()
        let emailCheckStateRelay = BehaviorRelay<EmailCheckState>(value: .none)
        let passwordValidationErrorRelay = PublishRelay<String?>()
        let nicknameValidationErrorRelay = PublishRelay<String?>()
        let isPasswordVisibleRelay = BehaviorRelay<Bool>(value: false)

        input.passwordToggleTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let currentValue = isPasswordVisibleRelay.value
                isPasswordVisibleRelay.accept(!currentValue)
            })
            .disposed(by: disposeBag)

        input.emailText
            .skip(until: input.emailEditingDidBegin)
            .withUnretained(self)
            .do(onNext: { owner, email in
                emailCheckStateRelay.accept(.none)
                if email.isEmpty {
                    emailValidationErrorRelay.accept("이메일을 입력해주세요")
                } else if owner.validateEmail(email) {
                    emailValidationErrorRelay.accept(nil)
                } else {
                    emailValidationErrorRelay.accept("올바른 이메일 형식이 아닙니다")
                }
            })
            .map { $0.1 }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .filter { owner, email in
                !email.isEmpty && owner.validateEmail(email)
            }
            .flatMapLatest { owner, email in
                owner.userRepository.validateEmail(email)
                    .asObservable()
                    .map { _ in EmailCheckState.available }
                    .catch { error in
                        return .just(EmailCheckState.unavailable)
                    }
            }
            .subscribe(onNext: { state in
                emailCheckStateRelay.accept(state)
            })
            .disposed(by: disposeBag)

        input.passwordText
            .skip(until: input.passwordEditingDidBegin)
            .withUnretained(self)
            .subscribe(onNext: { owner, password in
                if password.isEmpty {
                    passwordValidationErrorRelay.accept("비밀번호를 입력해주세요")
                } else {
                    let validationResult = owner.validatePassword(password)
                    passwordValidationErrorRelay.accept(validationResult)
                }
            })
            .disposed(by: disposeBag)

        input.nicknameText
            .skip(until: input.nicknameEditingDidBegin)
            .withUnretained(self)
            .subscribe(onNext: { owner, nickname in
                if nickname.isEmpty {
                    nicknameValidationErrorRelay.accept("닉네임을 입력해주세요")
                } else {
                    let validationResult = owner.validateNickname(nickname)
                    nicknameValidationErrorRelay.accept(validationResult)
                }
            })
            .disposed(by: disposeBag)

        let isSignUpButtonEnabled = Observable.combineLatest(
            input.emailText,
            input.passwordText,
            input.nicknameText,
            emailCheckStateRelay.asObservable()
        )
        .withUnretained(self)
        .map { owner, values in
            let (email, password, nickname, checkState) = values
            return owner.validateEmail(email) &&
                   owner.validatePassword(password) == nil &&
                   owner.validateNickname(nickname) == nil &&
                   checkState == .available
        }

        let signUpInputs = Observable.combineLatest(
            input.emailText,
            input.passwordText,
            input.nicknameText,
            input.phoneText,
            input.introductionText
        )

        input.signUpButtonTapped
            .withLatestFrom(signUpInputs)
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, values in
                owner.performSignUp(
                    values: values,
                    loadingRelay: loadingRelay,
                    errorRelay: errorRelay
                )
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, response in
                loadingRelay.accept(false)
                owner.saveTokens(
                    response: response,
                    successRelay: successRelay,
                    errorRelay: errorRelay
                )
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            signUpSuccess: successRelay.asDriver(onErrorDriveWith: .empty()),
            signUpError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류"),
            emailValidationError: emailValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            emailCheckState: emailCheckStateRelay.asDriver(),
            passwordValidationError: passwordValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            nicknameValidationError: nicknameValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            isSignUpButtonEnabled: isSignUpButtonEnabled.asDriver(onErrorJustReturn: false),
            isPasswordVisible: isPasswordVisibleRelay.asDriver()
        )
    }

    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    private func validatePassword(_ password: String) -> String? {
        if password.count < 8 {
            return "비밀번호는 8자 이상이어야 합니다"
        }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil

        if !hasLetter {
            return "비밀번호는 영문을 포함해야 합니다"
        }

        if !hasNumber {
            return "비밀번호는 숫자를 포함해야 합니다"
        }

        if !hasSpecial {
            return "비밀번호는 특수문자(@$!%*#?&)를 포함해야 합니다"
        }

        return nil
    }

    private func validateNickname(_ nickname: String) -> String? {
        if nickname.count < 1 || nickname.count > 10 {
            return "닉네임은 1-10자 이내로 입력해주세요"
        }

        let forbiddenChars = "[\\-.,?*@+^${}()\\[\\]\\\\|]"
        if nickname.range(of: forbiddenChars, options: .regularExpression) != nil {
            return "닉네임에 특수문자를 사용할 수 없습니다"
        }

        return nil
    }

    private func performSignUp(
        values: (String, String, String, String, String),
        loadingRelay: PublishRelay<Bool>,
        errorRelay: PublishRelay<String>
    ) -> Observable<JoinResponse> {
        let (email, password, nickname, phone, introduction) = values
        let cleanedPhone = phone.replacingOccurrences(of: "-", with: "")

        let request = JoinRequest(
            email: email,
            password: password,
            nick: nickname,
            phoneNum: cleanedPhone.isEmpty ? "" : cleanedPhone,
            introduction: introduction.isEmpty ? "" : introduction,
            deviceToken: "temp-device-token"
        )

        return userRepository.join(request)
            .asObservable()
            .catch { error in
                loadingRelay.accept(false)
                errorRelay.accept(error.localizedDescription)
                return .empty()
            }
    }

    private func saveTokens(
        response: JoinResponse,
        successRelay: PublishRelay<(nickname: String, email: String)>,
        errorRelay: PublishRelay<String>
    ) {
        do {
            try container.authService.login(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            successRelay.accept((nickname: response.nick, email: response.email))
        } catch {
            errorRelay.accept("토큰 저장에 실패했습니다.")
        }
    }
}
