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

    private let scrollView = UIScrollView().then {
        $0.keyboardDismissMode = .onDrag
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1, text: "회원가입")
        $0.textColor = ColorSystem.gray90
    }

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

    private let emailValidationLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1, text: "")
        $0.textColor = .systemGreen
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
        $0.typography(FontSystem.Pretendard.caption1, text: "")
        $0.textColor = .systemRed
        $0.isHidden = true
    }

    private let nicknameTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "닉네임")
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.gray45.cgColor
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.rightViewMode = .always
    }

    private let nicknameErrorLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1, text: "")
        $0.textColor = .systemRed
        $0.isHidden = true
    }

    private let phoneTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "전화번호 (선택)")
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.gray45.cgColor
        $0.keyboardType = .numberPad
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        $0.rightViewMode = .always
    }

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
        customNavigationBar = addCustomNavigationBar(showBackButton: true)
        enableSwipeBackGesture()
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
            .paddingTop(40)
            .define { flex in
                flex.addItem(titleLabel)
                    .marginBottom(24)

                flex.addItem(emailTextField)
                    .height(48)
                    .marginBottom(4)

                flex.addItem(emailValidationLabel)
                    .height(16)
                    .marginBottom(12)

                flex.addItem(passwordContainer)
                    .height(48)
                    .marginBottom(4)

                flex.addItem(passwordErrorLabel)
                    .height(16)
                    .marginBottom(12)

                flex.addItem(nicknameTextField)
                    .height(48)
                    .marginBottom(4)

                flex.addItem(nicknameErrorLabel)
                    .height(16)
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
        let input = SignUpPresenter.Input(
            emailText: emailTextField.rx.text.orEmpty.asObservable(),
            passwordText: passwordTextField.rx.text.orEmpty.asObservable(),
            nicknameText: nicknameTextField.rx.text.orEmpty.asObservable(),
            phoneText: phoneTextField.rx.text.orEmpty.asObservable(),
            introductionText: introductionTextView.rx.text.orEmpty.asObservable(),
            signUpButtonTapped: signUpButton.rx.tap.asObservable(),
            emailEditingDidEnd: emailTextField.rx.controlEvent(.editingDidEnd).asObservable(),
            passwordEditingDidBegin: passwordTextField.rx.controlEvent(.editingDidBegin).asObservable(),
            nicknameEditingDidBegin: nicknameTextField.rx.controlEvent(.editingDidBegin).asObservable()
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
            .drive(with: self) { owner, _ in
                let alert = UIAlertController(
                    title: "회원가입 완료",
                    message: "회원가입이 완료되었습니다!",
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        customNavigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        scrollView.pin
            .below(of: customNavigationBar)
            .left()
            .right()
            .bottom(view.pin.safeArea.bottom)

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
