import Foundation
import RxSwift
import RxCocoa

final class LoginPresenter {
    private let userRepository: UserRepository
    private let disposeBag = DisposeBag()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    struct Input {
        let appleLoginTapped: Observable<Void>
        let appleIdToken: Observable<String>
    }

    struct Output {
        let isLoading: Driver<Bool>
        let loginSuccess: Driver<(nickname: String, email: String)>
        let loginError: Driver<String>
        let appleLoginTrigger: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let successRelay = PublishRelay<(nickname: String, email: String)>()
        let errorRelay = PublishRelay<String>()
        let appleLoginTriggerRelay = PublishRelay<Void>()

        input.appleLoginTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                appleLoginTriggerRelay.accept(())
            })
            .disposed(by: disposeBag)

        input.appleIdToken
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
            loginError: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류"),
            appleLoginTrigger: appleLoginTriggerRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
