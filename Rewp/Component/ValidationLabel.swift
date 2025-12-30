//
//  ValidationLabel.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import Then
import FlexLayout

final class ValidationLabel: UILabel {
    enum ValidationType {
        case error
        case success
        case info
    }

    init() {
        super.init(frame: .zero)

        self.typography(FontSystem.Pretendard.caption1, text: "")
        self.isHidden = true
        self.flex.isIncludedInLayout(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ message: String, type: ValidationType = .error) {
        typography(FontSystem.Pretendard.caption1, text: message)
        textColor = color(for: type)
        isHidden = false
        flex.isIncludedInLayout(true)
        flex.markDirty()
    }

    func hide() {
        isHidden = true
        flex.isIncludedInLayout(false)
        flex.markDirty()
    }

    private func color(for type: ValidationType) -> UIColor {
        switch type {
        case .error:
            return .systemRed
        case .success:
            return .systemGreen
        case .info:
            return ColorSystem.gray60
        }
    }
}
