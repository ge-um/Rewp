//
//  CategoryCardSmall.swift
//  Rewp
//
//  Created by 금가경 on 02/04/26.
//

import UIKit
import PinLayout
import Then

final class CategoryCardSmall: UIView {
    private let containerView = UIView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let gradientLayer = CAGradientLayer().then {
        $0.colors = [
            UIColor(hex: "#83ABFB").cgColor,
            UIColor(hex: "#567DF3").cgColor
        ]
        $0.startPoint = CGPoint(x: 0.5, y: 0)
        $0.endPoint = CGPoint(x: 0.5, y: 1)
        $0.cornerRadius = 12
    }

    private let shadowView = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 12
        $0.layer.applyShadow(ShadowSystem.sm)
    }

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    var onTap: (() -> Void)?

    init(title: String, icon: UIImage?) {
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body2Bold, text: title)
        iconImageView.image = icon
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(shadowView)
        addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.addSubview(titleLabel)
        containerView.addSubview(iconImageView)
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        shadowView.pin.all()
        containerView.pin.all()
        gradientLayer.frame = containerView.bounds

        titleLabel.pin
            .top(12)
            .left(12)
            .sizeToFit()

        iconImageView.pin
            .right(12)
            .bottom(12)
            .size(36)
    }
}
