//
//  SignUpViewController.swift
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

final class SignUpViewController: UIViewController {
    var presenter: SignUpPresenter!

    private var customNavigationBar: CustomNavigationBar!

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1Bold, text: "회원가입")
        $0.textColor = ColorSystem.gray90
    }

    private let emailTextField = FormTextField(
        placeholder: "이메일",
        keyboardType: .emailAddress
    )

    private let emailErrorLabel = ValidationLabel()

    private let passwordTextField = PasswordTextField()

    private let passwordErrorLabel = ValidationLabel()

    private let nicknameTextField = FormTextField(placeholder: "닉네임")

    private let nicknameErrorLabel = ValidationLabel()

    private let phoneTextField = FormTextField(
        placeholder: "전화번호 (선택)",
        keyboardType: .numberPad
    )

    private let introductionTextView = PlaceholderTextView().then {
        $0.placeholder = "소개 (선택)"
    }

    private let signUpButton = UIButton().then {
        $0.backgroundColor = ColorSystem.gray45
        $0.layer.cornerRadius = 12
        $0.isEnabled = false

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        var titleAttr = AttributedString("회원가입")
        titleAttr.font = FontSystem.Pretendard.body1.font
        titleAttr.foregroundColor = ColorSystem.gray0
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray0

        $0.configuration = config
    }

    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        customNavigationBar = addCustomNavigationBar()
        enableSwipeBackGesture()
        setupUI()
        setupKeyboardDismiss()
        bind()
    }

    private func setupUI() {
        view.addSubview(contentView)
        view.addSubview(activityIndicator)

        contentView.flex
            .direction(.column)
            .paddingHorizontal(36)
            .paddingTop(40)
            .define { flex in
                flex.addItem(titleLabel)
                    .marginBottom(24)

                flex.addItem(emailTextField)
                    .height(48)
                    .marginBottom(12)

                flex.addItem(emailErrorLabel)
                    .marginBottom(12)

                flex.addItem(passwordTextField)
                    .height(48)
                    .marginBottom(12)

                flex.addItem(passwordErrorLabel)
                    .marginBottom(12)

                flex.addItem(nicknameTextField)
                    .height(48)
                    .marginBottom(12)

                flex.addItem(nicknameErrorLabel)
                    .marginBottom(12)

                flex.addItem(phoneTextField)
                    .height(48)
                    .marginBottom(12)

                flex.addItem(introductionTextView)
                    .height(100)
                    .marginBottom(12)

                flex.addItem(signUpButton)
                    .height(56)
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
        phoneTextField.rx.text.orEmpty
            .withUnretained(self)
            .map { owner, text in
                owner.formatPhoneNumber(text)
            }
            .bind(to: phoneTextField.rx.text)
            .disposed(by: disposeBag)

        let input = SignUpPresenter.Input(
            emailText: emailTextField.rx.text.orEmpty.asObservable(),
            passwordText: passwordTextField.text.orEmpty.asObservable(),
            nicknameText: nicknameTextField.rx.text.orEmpty.asObservable(),
            phoneText: phoneTextField.rx.text.orEmpty.asObservable(),
            introductionText: introductionTextView.rx.text.orEmpty.asObservable(),
            signUpButtonTapped: signUpButton.rx.tap.asObservable(),
            emailEditingDidBegin: emailTextField.rx.controlEvent(.editingDidBegin).asObservable(),
            passwordEditingDidBegin: passwordTextField.editingDidBegin.asObservable(),
            nicknameEditingDidBegin: nicknameTextField.rx.controlEvent(.editingDidBegin).asObservable(),
            passwordToggleTapped: passwordTextField.toggleTapped
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

        output.signUpSuccess
            .drive(with: self) { owner, result in
                let alert = UIAlertController(
                    title: "회원가입 완료",
                    message: "\(result.nickname)님, 환영합니다!",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    owner.navigationController?.popViewController(animated: true)
                })
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.signUpError
            .drive(with: self) { owner, errorMessage in
                owner.showError(errorMessage)
            }
            .disposed(by: disposeBag)

        let emailMessage = Driver.combineLatest(
            output.emailValidationError,
            output.emailCheckState
        )
        .map { validationError, checkState -> (message: String?, type: ValidationLabel.ValidationType, hasError: Bool) in
            if let validationError = validationError {
                return (validationError, .error, true)
            }

            switch checkState {
            case .none:
                return (nil, .error, false)
            case .available:
                return ("사용 가능한 이메일입니다", .success, false)
            case .unavailable:
                return ("이미 사용 중인 이메일입니다", .error, true)
            }
        }

        emailMessage
            .drive(with: self) { owner, result in
                if let message = result.message {
                    owner.emailErrorLabel.show(message, type: result.type)
                    owner.emailTextField.setError(result.hasError)
                } else {
                    owner.emailErrorLabel.hide()
                    owner.emailTextField.setError(false)
                }
                owner.contentView.flex.layout()
            }
            .disposed(by: disposeBag)

        output.passwordValidationError
            .drive(with: self) { owner, errorMessage in
                if let errorMessage = errorMessage {
                    owner.passwordErrorLabel.show(errorMessage, type: .error)
                    owner.passwordTextField.setError(true)
                } else {
                    owner.passwordErrorLabel.hide()
                    owner.passwordTextField.setError(false)
                }
                owner.contentView.flex.layout()
            }
            .disposed(by: disposeBag)

        output.nicknameValidationError
            .drive(with: self) { owner, errorMessage in
                if let errorMessage = errorMessage {
                    owner.nicknameErrorLabel.show(errorMessage, type: .error)
                    owner.nicknameTextField.setError(true)
                } else {
                    owner.nicknameErrorLabel.hide()
                    owner.nicknameTextField.setError(false)
                }
                owner.contentView.flex.layout()
            }
            .disposed(by: disposeBag)

        output.isSignUpButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.signUpButton.isEnabled = isEnabled
                owner.signUpButton.backgroundColor = isEnabled ? ColorSystem.deepCoast : ColorSystem.gray45
            }
            .disposed(by: disposeBag)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "회원가입 실패",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func formatPhoneNumber(_ text: String) -> String {
        let digits = text.filter { $0.isNumber }
        let maxLength = min(digits.count, 11)
        let limitedDigits = String(digits.prefix(maxLength))

        if limitedDigits.count >= 11 {
            let index3 = limitedDigits.index(limitedDigits.startIndex, offsetBy: 3)
            let index7 = limitedDigits.index(limitedDigits.startIndex, offsetBy: 7)
            return "\(limitedDigits[..<index3])-\(limitedDigits[index3..<index7])-\(limitedDigits[index7...])"
        } else if limitedDigits.count >= 7 {
            let index3 = limitedDigits.index(limitedDigits.startIndex, offsetBy: 3)
            let index7 = limitedDigits.index(limitedDigits.startIndex, offsetBy: 7)
            return "\(limitedDigits[..<index3])-\(limitedDigits[index3..<index7])-\(limitedDigits[index7...])"
        } else if limitedDigits.count >= 3 {
            let index3 = limitedDigits.index(limitedDigits.startIndex, offsetBy: 3)
            return "\(limitedDigits[..<index3])-\(limitedDigits[index3...])"
        }
        return limitedDigits
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        customNavigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        contentView.pin
            .below(of: customNavigationBar)
            .horizontally()
            .bottom(view.pin.safeArea.bottom)

        contentView.flex.layout()

        activityIndicator.pin
            .center()
    }
}
