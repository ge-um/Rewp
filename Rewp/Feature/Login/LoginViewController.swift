//
//  LoginViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

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

    private let scrollView = UIScrollView().then {
        $0.keyboardDismissMode = .onDrag
        $0.showsVerticalScrollIndicator = false
    }

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
        $0.backgroundColor = ColorSystem.kakaoYellow
        $0.layer.cornerRadius = 12

        var config = UIButton.Configuration.plain()
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
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

    private let emailFieldsContainer = UIView()

    private let emailTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "이메일")
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.gray45.cgColor
        $0.keyboardType = .emailAddress
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.rightViewMode = .always
    }

    private let emailErrorLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption3, text: "")
        $0.textColor = .systemRed
        $0.isHidden = true
    }

    private let passwordContainer = UIView()

    private let passwordTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "비밀번호")
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.gray45.cgColor
        $0.isSecureTextEntry = true
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 48))
        $0.rightViewMode = .always
    }

    private let passwordToggleButton = UIButton().then {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let icon = UIImage(systemName: "eye.slash.fill", withConfiguration: iconConfig)
        $0.setImage(icon, for: .normal)
        $0.tintColor = ColorSystem.gray60
    }

    private let passwordErrorLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption3, text: "")
        $0.textColor = .systemRed
        $0.isHidden = true
    }

    private let emailLoginButton = UIButton().then {
        $0.backgroundColor = ColorSystem.gray45
        $0.layer.cornerRadius = 12
        $0.isEnabled = false

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        var titleAttr = AttributedString("로그인")
        titleAttr.font = FontSystem.Pretendard.body1.font
        titleAttr.foregroundColor = ColorSystem.gray0
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray0

        $0.configuration = config
    }

    private let signUpButton = UIButton().then {
        var config = UIButton.Configuration.plain()

        var titleAttr = AttributedString("계정이 없으신가요?")
        titleAttr.font = FontSystem.Pretendard.caption1.font
        titleAttr.foregroundColor = ColorSystem.gray60
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray60
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
        setupKeyboardDismiss()
        bind()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(activityIndicator)

        passwordContainer.addSubview(passwordTextField)
        passwordContainer.addSubview(passwordToggleButton)

        contentView.flex
            .direction(.column)
            .paddingHorizontal(36)
            .paddingTop(200)
            .define { flex in
                flex.addItem(titleLabel)
                    .marginBottom(24)

                flex.addItem(emailFieldsContainer)
                    .direction(.column)
                    .define { flex in
                        flex.addItem(emailTextField)
                            .height(48)
                            .marginBottom(4)

                        flex.addItem(emailErrorLabel)
                            .height(16)
                            .marginBottom(8)

                        flex.addItem(passwordContainer)
                            .height(48)
                            .marginBottom(4)

                        flex.addItem(passwordErrorLabel)
                            .height(16)
                            .marginBottom(8)

                        flex.addItem(emailLoginButton)
                            .height(56)
                    }
                    .marginBottom(12)

                flex.addItem(kakaoLoginButton)
                    .height(56)
                    .marginBottom(12)

                flex.addItem(appleLoginButton)
                    .height(56)
                    .marginBottom(12)

                flex.addItem(signUpButton)
                    .height(32)
            }
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func bind() {
        let input = LoginPresenter.Input(
            appleLoginTapped: appleLoginButton.rx.tap.asObservable(),
            kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable(),
            emailText: emailTextField.rx.text.orEmpty.asObservable(),
            passwordText: passwordTextField.rx.text.orEmpty.asObservable(),
            emailLoginButtonTapped: emailLoginButton.rx.tap.asObservable(),
            passwordToggleTapped: passwordToggleButton.rx.tap.asObservable(),
            emailEditingDidBegin: emailTextField.rx.controlEvent(.editingDidBegin).asObservable(),
            passwordEditingDidBegin: passwordTextField.rx.controlEvent(.editingDidBegin).asObservable()
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

        output.emailValidationError
            .drive(with: self) { owner, errorMessage in
                if let errorMessage = errorMessage {
                    owner.emailErrorLabel.typography(FontSystem.Pretendard.caption1, text: errorMessage)
                    owner.emailErrorLabel.isHidden = false
                    owner.emailTextField.layer.borderColor = UIColor.systemRed.cgColor
                } else {
                    owner.emailErrorLabel.isHidden = true
                    owner.emailTextField.layer.borderColor = ColorSystem.gray45.cgColor
                }
            }
            .disposed(by: disposeBag)

        output.passwordValidationError
            .drive(with: self) { owner, errorMessage in
                if let errorMessage = errorMessage {
                    owner.passwordErrorLabel.typography(FontSystem.Pretendard.caption1, text: errorMessage)
                    owner.passwordErrorLabel.isHidden = false
                    owner.passwordTextField.layer.borderColor = UIColor.systemRed.cgColor
                } else {
                    owner.passwordErrorLabel.isHidden = true
                    owner.passwordTextField.layer.borderColor = ColorSystem.gray45.cgColor
                }
            }
            .disposed(by: disposeBag)

        output.isEmailLoginButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.emailLoginButton.isEnabled = isEnabled
                owner.emailLoginButton.backgroundColor = isEnabled ? ColorSystem.deepCoast : ColorSystem.gray45
            }
            .disposed(by: disposeBag)

        output.isPasswordVisible
            .drive(with: self) { owner, isVisible in
                owner.passwordTextField.isSecureTextEntry = !isVisible
                let iconName = isVisible ? "eye.fill" : "eye.slash.fill"
                let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                let icon = UIImage(systemName: iconName, withConfiguration: iconConfig)
                owner.passwordToggleButton.setImage(icon, for: .normal)
            }
            .disposed(by: disposeBag)

        signUpButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let signUpVC = owner.container.makeSignUpViewController()
                owner.navigationController?.pushViewController(signUpVC, animated: true)
            })
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

        scrollView.pin
            .all(view.pin.safeArea)

        contentView.pin
            .top()
            .horizontally()

        contentView.flex.layout(mode: .adjustHeight)

        scrollView.contentSize = contentView.frame.size

        passwordTextField.pin
            .all()

        passwordToggleButton.pin
            .right(12)
            .vCenter()
            .size(24)

        activityIndicator.pin
            .center()
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
