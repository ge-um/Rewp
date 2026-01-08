//
//  PasswordTextField.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import Then

final class PasswordTextField: UIView {
    private let textField = UITextField().then {
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

    private let toggleButton = UIButton().then {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let icon = UIImage(systemName: "eye.slash.fill", withConfiguration: iconConfig)
        $0.setImage(icon, for: .normal)
        $0.tintColor = ColorSystem.gray60
    }

    private let isPasswordVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()

    var text: ControlProperty<String?> {
        return textField.rx.text
    }

    var editingDidBegin: ControlEvent<Void> {
        return textField.rx.controlEvent(.editingDidBegin)
    }

    var toggleTapped: Observable<Void> {
        return toggleButton.rx.tap.asObservable()
    }

    var isPasswordVisible: Driver<Bool> {
        return isPasswordVisibleRelay.asDriver()
    }

    init(placeholder: String = "비밀번호") {
        super.init(frame: .zero)

        textField.placeholder = placeholder

        addSubview(textField)
        addSubview(toggleButton)

        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBindings() {
        toggleButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let newValue = !owner.isPasswordVisibleRelay.value
                owner.isPasswordVisibleRelay.accept(newValue)
                owner.updateToggleState(isVisible: newValue)
            })
            .disposed(by: disposeBag)
    }

    private func updateToggleState(isVisible: Bool) {
        textField.isSecureTextEntry = !isVisible
        let iconName = isVisible ? "eye.fill" : "eye.slash.fill"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let icon = UIImage(systemName: iconName, withConfiguration: iconConfig)
        toggleButton.setImage(icon, for: .normal)
    }

    func setError(_ hasError: Bool) {
        textField.layer.borderColor = hasError ? UIColor.systemRed.cgColor : ColorSystem.gray45.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textField.frame = bounds

        toggleButton.frame = CGRect(
            x: bounds.width - 36,
            y: (bounds.height - 24) / 2,
            width: 24,
            height: 24
        )
    }
}
