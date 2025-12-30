//
//  RewpTextField.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import Then

final class FormTextField: UITextField {
    init(
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .none,
        autocorrectionType: UITextAutocorrectionType = .no
    ) {
        super.init(frame: .zero)

        self.typography(FontSystem.Pretendard.body2, placeholder: placeholder)
        self.textColor = ColorSystem.gray90
        self.backgroundColor = ColorSystem.gray0
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = ColorSystem.gray45.cgColor
        self.keyboardType = keyboardType
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType

        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        self.leftViewMode = .always
        self.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        self.rightViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setError(_ hasError: Bool) {
        layer.borderColor = hasError ? UIColor.systemRed.cgColor : ColorSystem.gray45.cgColor
    }
}
