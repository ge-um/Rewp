import Foundation
import RxSwift
import RxCocoa

final class EmailLoginPresenter {
    private let userRepository: UserRepository
    private let disposeBag = DisposeBag()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    struct Input {
        let emailText: Observable<String>
        let passwordText: Observable<String>
        let loginButtonTapped: Observable<Void>
        let passwordToggleTapped: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let loginSuccess: Driver<(nickname: String, email: String)>
        let loginError: Driver<String>
        let emailValidationError: Driver<String?>
        let isLoginButtonEnabled: Driver<Bool>
        let isPasswordVisible: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<(nickname: String, email: String)>()
        let errorRelay = PublishRelay<String>()
        let isPasswordVisibleRelay = BehaviorRelay<Bool>(value: false)
        let emailValidationErrorRelay = BehaviorRelay<String?>(value: nil)

        input.passwordToggleTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let currentValue = isPasswordVisibleRelay.value
                isPasswordVisibleRelay.accept(!currentValue)
            })
            .disposed(by: disposeBag)

        input.emailText
            .skip(1)
            .withUnretained(self)
            .subscribe(onNext: { owner, email in
                guard !email.isEmpty else {
                    emailValidationErrorRelay.accept(nil)
                    return
                }
                if owner.validateEmail(email) {
                    emailValidationErrorRelay.accept(nil)
                } else {
                    emailValidationErrorRelay.accept("올바른 이메일 형식이 아닙니다")
                }
            })
            .disposed(by: disposeBag)

        let isLoginButtonEnabled = Observable.combineLatest(
            input.emailText,
            input.passwordText
        )
        .withUnretained(self)
        .map { owner, values in
            let (email, password) = values
            return owner.validateEmail(email) && password.count >= 6
        }

        input.loginButtonTapped
            .withLatestFrom(Observable.combineLatest(input.emailText, input.passwordText))
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, values in
                let (email, password) = values
                return owner.userRepository.login(email: email, password: password)
                    .asObservable()
                    .catch { error in
                        loadingRelay.accept(false)
                        errorRelay.accept(error.localizedDescription)
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, response in
                loadingRelay.accept(false)
                do {
                    try KeychainManager.shared.saveAccessToken(response.accessToken)
                    try KeychainManager.shared.saveRefreshToken(response.refreshToken)
                    successRelay.accept((nickname: response.nick, email: response.email))
                } catch {
                    errorRelay.accept("토큰 저장에 실패했습니다.")
                }
            })
            .disposed(by: disposeBag)

        return Output(
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            loginSuccess: successRelay.asDriver(onErrorDriveWith: .empty()),
            loginError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류"),
            emailValidationError: emailValidationErrorRelay.asDriver(),
            isLoginButtonEnabled: isLoginButtonEnabled.asDriver(onErrorJustReturn: false),
            isPasswordVisible: isPasswordVisibleRelay.asDriver()
        )
    }

    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}
