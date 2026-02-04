//
//  FilterButton.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import UIKit
import PinLayout

final class FilterButton: UIView {
    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private var isActive = false

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body2, text: title)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setActive(_ active: Bool) {
        isActive = active
        updateAppearance()
    }

    private func setupUI() {
        addSubview(titleLabel)

        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = ColorSystem.gray45.cgColor
        backgroundColor = ColorSystem.gray0

        updateAppearance()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    private func updateAppearance() {
        let text = titleLabel.text ?? titleLabel.attributedText?.string ?? ""

        if isActive {
            titleLabel.typography(FontSystem.Pretendard.body2Bold, text: text, textColor: ColorSystem.brightWood)
            layer.borderColor = ColorSystem.brightWood.cgColor
        } else {
            titleLabel.typography(FontSystem.Pretendard.body2, text: text, textColor: ColorSystem.gray75)
            layer.borderColor = ColorSystem.gray75.cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.pin
            .center()
            .sizeToFit()
    }
    
    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 32))
        return CGSize(width: labelSize.width + 24, height: 32)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: size.height))
        return CGSize(width: labelSize.width + 24, height: 32)
    }
}
