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

    private let kakaoLoginButton = UIButton().then {
        $0.backgroundColor = UIColor(red: 254/255, green: 229/255, blue: 0/255, alpha: 1.0)
        $0.layer.cornerRadius = 12

        var config = UIButton.Configuration.plain()
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let icon = UIImage(systemName: "message.fill", withConfiguration: iconConfig)
        config.image = icon
        config.imagePlacement = .leading

        var titleAttr = AttributedString("카카오로 시작하기")
        titleAttr.font = FontSystem.Pretendard.body1.font
        titleAttr.foregroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1.0)
        config.attributedTitle = titleAttr

        config.baseForegroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1.0)

        $0.configuration = config
    }

    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        presenter.presentationContextProvider = self
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

                flex.addItem(kakaoLoginButton)
                    .height(56)
                    .marginBottom(12)

                flex.addItem(appleLoginButton)
                    .height(56)
                    .marginBottom(40)
            }
    }

    private func bind() {
        let input = LoginPresenter.Input(
            appleLoginTapped: appleLoginButton.rx.tap.asObservable(),
            kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable()
        )

        let output = presenter.transform(input: input)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.activityIndicator.startAnimating()
                } else {
                    owner.activityIndicator.stopAnimating()
                }
            }
            .disposed(by: disposeBag)

        output.loginSuccess
            .drive(with: self) { owner, result in
                owner.navigateToHome(nickname: result.nickname, email: result.email)
            }
            .disposed(by: disposeBag)

        output.loginError
            .drive(with: self) { owner, errorMessage in
                owner.showError(errorMessage)
            }
            .disposed(by: disposeBag)
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

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
