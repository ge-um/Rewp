import Foundation
import RxSwift
import RxCocoa
import AuthenticationServices
import KakaoSDKAuth
import KakaoSDKUser

final class LoginPresenter: NSObject {
    weak var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?

    private let userRepository: UserRepository
    private let disposeBag = DisposeBag()
    private let appleIdTokenSubject = PublishSubject<String>()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
    }

    struct Input {
        let appleLoginTapped: Observable<Void>
        let kakaoLoginTapped: Observable<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let loginSuccess: Driver<(nickname: String, email: String)>
        let loginError: Driver<String>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<(nickname: String, email: String)>()
        let errorRelay = PublishRelay<String>()

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
                    try KeychainManager.shared.saveAccessToken(response.accessToken)
                    try KeychainManager.shared.saveRefreshToken(response.refreshToken)
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
            loginError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류")
        )
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
