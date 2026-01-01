//
//  OptionLabel.swift
//  Rewp
//
//  Created by 금가경 on 12/17/25.
//

import UIKit
import PinLayout
import Then

final class OptionLabel: UIView {
    private let iconName: String
    private let title: String

    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption2, text: title)
        $0.textAlignment = .center
    }

    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    init(iconName: String, title: String) {
        self.iconName = iconName
        self.title = title
        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
    }

    private func updateAppearance() {
        if isSelected {
            iconImageView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = ColorSystem.gray75
            titleLabel.textColor = ColorSystem.gray75
        } else {
            iconImageView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = ColorSystem.gray30
            titleLabel.textColor = ColorSystem.gray30
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        iconImageView.pin
            .top()
            .hCenter()
            .size(32)

        titleLabel.pin
            .below(of: iconImageView)
            .marginTop(8)
            .horizontally()
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 54, height: 54)
    }
}

@available(iOS 17.0, *)
#Preview("Not Selected") {
    OptionLabel(iconName: "Refrigerator", title: "냉장고")
}

@available(iOS 17.0, *)
#Preview("Selected") {
    OptionLabel(iconName: "Refrigerator", title: "냉장고").then {
        $0.isSelected = true
    }
}
