//
//  LoginPresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import Foundation
import RxSwift
import RxCocoa
import AuthenticationServices
import KakaoSDKAuth
import KakaoSDKUser

final class LoginPresenter: NSObject {
    weak var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?

    private let userRepository: UserRepository
    private let container: AppContainer
    private let disposeBag = DisposeBag()
    private let appleIdTokenSubject = PublishSubject<String>()

    init(userRepository: UserRepository, container: AppContainer) {
        self.userRepository = userRepository
        self.container = container
        super.init()
    }

    struct Input {
        let appleLoginTapped: Observable<Void>
        let kakaoLoginTapped: Observable<Void>
        let emailText: Observable<String>
        let passwordText: Observable<String>
        let emailLoginButtonTapped: Observable<Void>
        let passwordToggleTapped: Observable<Void>
        let emailEditingDidBegin: Observable<Void>
        let passwordEditingDidBegin: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let loginSuccess: Driver<(nickname: String, email: String)>
        let loginError: Driver<String>
        let emailValidationError: Driver<String?>
        let passwordValidationError: Driver<String?>
        let isEmailLoginButtonEnabled: Driver<Bool>
        let isPasswordVisible: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<(nickname: String, email: String)>()
        let errorRelay = PublishRelay<String>()
        let isPasswordVisibleRelay = BehaviorRelay<Bool>(value: false)
        let emailValidationErrorRelay = PublishRelay<String?>()
        let passwordValidationErrorRelay = PublishRelay<String?>()

        input.appleLoginTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.performAppleLogin()
            })
            .disposed(by: disposeBag)

        input.kakaoLoginTapped
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, _ in
                owner.performKakaoLogin()
                    .catch { error in
                        loadingRelay.accept(false)
                        errorRelay.accept(error.localizedDescription)
                        return .empty()
                    }
            }
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, oauthToken in
                owner.userRepository.kakaoLogin(
                    oauthToken: oauthToken,
                    deviceToken: "temp-device-token"
                )
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
                    try owner.container.authService.login(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    successRelay.accept((nickname: response.nick, email: response.email))
                } catch {
                    errorRelay.accept("토큰 저장에 실패했습니다.")
                }
            })
            .disposed(by: disposeBag)

        appleIdTokenSubject
            .withUnretained(self)
            .do(onNext: { owner, _ in
                loadingRelay.accept(true)
            })
            .flatMapLatest { owner, idToken in
                owner.userRepository.appleLogin(
                    idToken: idToken,
                    deviceToken: "temp-device-token"
                )
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
                    try owner.container.authService.login(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    successRelay.accept((nickname: response.nick, email: response.email))
                } catch {
                    errorRelay.accept("토큰 저장에 실패했습니다.")
                }
            })
            .disposed(by: disposeBag)

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
            .subscribe(onNext: { owner, email in
                if email.isEmpty {
                    emailValidationErrorRelay.accept("이메일을 입력해주세요")
                } else if owner.validateEmail(email) {
                    emailValidationErrorRelay.accept(nil)
                } else {
                    emailValidationErrorRelay.accept("올바른 이메일 형식이 아닙니다")
                }
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

        let isEmailLoginButtonEnabled = Observable.combineLatest(
            input.emailText,
            input.passwordText
        )
        .withUnretained(self)
        .map { owner, values in
            let (email, password) = values
            return owner.validateEmail(email) && owner.validatePassword(password) == nil
        }

        input.emailLoginButtonTapped
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
                    try owner.container.authService.login(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
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
            emailValidationError: emailValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            passwordValidationError: passwordValidationErrorRelay.startWith(nil).asDriver(onErrorJustReturn: nil),
            isEmailLoginButtonEnabled: isEmailLoginButtonEnabled.asDriver(onErrorJustReturn: false),
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

        if !hasLetter {
            return "비밀번호는 영문을 포함해야 합니다"
        }

        if !hasNumber {
            return "비밀번호는 숫자를 포함해야 합니다"
        }

        return nil
    }

    private func performKakaoLogin() -> Observable<String> {
        return Observable.create { observer in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        observer.onError(error)
                    } else if let token = oauthToken {
                        observer.onNext(token.accessToken)
                        observer.onCompleted()
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        observer.onError(error)
                    } else if let token = oauthToken {
                        observer.onNext(token.accessToken)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }

    private func performAppleLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = presentationContextProvider
        controller.performRequests()
    }
}

extension LoginPresenter: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            return
        }
        appleIdTokenSubject.onNext(identityToken)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    }
}
