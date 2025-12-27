import UIKit
import RxSwift
import RxCocoa
import PinLayout
import FlexLayout
import Then
import AuthenticationServices

final class LoginViewController: UIViewController {
    var presenter: LoginPresenter!
    var container: AppContainer!

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1, text: "시작하기")
        $0.textColor = ColorSystem.gray90
    }

    private let appleLoginButton = UIButton().then {
        $0.backgroundColor = ColorSystem.gray90
        $0.layer.cornerRadius = 12

        var config = UIButton.Configuration.plain()
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let icon = UIImage(systemName: "apple.logo", withConfiguration: iconConfig)
        config.image = icon
        config.imagePlacement = .leading

        var titleAttr = AttributedString("Apple로 시작하기")
        titleAttr.font = FontSystem.Pretendard.body1.font
        titleAttr.foregroundColor = ColorSystem.gray0
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray0

        $0.configuration = config
    }

    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
    }

    private let appleIdTokenSubject = PublishSubject<String>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        bind()
    }

    private func setupUI() {
        view.addSubview(contentView)
        view.addSubview(activityIndicator)

        contentView.flex
            .direction(.column)
            .padding(36)
            .define { flex in
                flex.addItem()
                    .grow(1)

                flex.addItem(titleLabel)
                    .marginBottom(24)

                flex.addItem(appleLoginButton)
                    .height(56)
                    .marginBottom(40)
            }
    }

    private func bind() {
        let input = LoginPresenter.Input(
            appleLoginTapped: appleLoginButton.rx.tap.asObservable(),
            appleIdToken: appleIdTokenSubject.asObservable()
        )

        let output = presenter.transform(input: input)

        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        output.loginSuccess
            .drive(onNext: { [weak self] nickname, email in
                self?.navigateToHome(nickname: nickname, email: email)
            })
            .disposed(by: disposeBag)

        output.loginError
            .drive(onNext: { [weak self] errorMessage in
                self?.showError(errorMessage)
            })
            .disposed(by: disposeBag)

        output.appleLoginTrigger
            .drive(onNext: { [weak self] in
                self?.performAppleLogin()
            })
            .disposed(by: disposeBag)
    }

    private func performAppleLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    private func navigateToHome(nickname: String, email: String) {
        let homeVC = container.makeHomeViewController()
        navigationController?.setViewControllers([homeVC], animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "로그인 실패",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        contentView.pin
            .all(view.pin.safeArea)

        contentView.flex.layout()

        activityIndicator.pin
            .center()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            showError("애플 로그인 정보를 가져올 수 없습니다.")
            return
        }
        appleIdTokenSubject.onNext(identityToken)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showError("애플 로그인에 실패했습니다.")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
