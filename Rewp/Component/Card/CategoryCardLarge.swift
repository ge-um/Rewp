//
//  CategoryCardLarge.swift
//  Rewp
//
//  Created by 금가경 on 02/04/26.
//

import UIKit
import PinLayout
import FlexLayout
import Then

final class CategoryCardLarge: UIView {
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

    private let badgeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.backgroundColor = ColorSystem.deepCream
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.textAlignment = .center
        $0.isHidden = true
    }

    var onTap: (() -> Void)?

    init(title: String, icon: UIImage?, badge: String? = nil) {
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body1Bold, text: title)
        iconImageView.image = icon
        if let badge = badge {
            badgeLabel.typography(FontSystem.Pretendard.caption2, text: badge)
            badgeLabel.isHidden = false
        }
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
        containerView.addSubview(badgeLabel)
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
            .top(16)
            .left(16)
            .sizeToFit()

        iconImageView.pin
            .right(16)
            .bottom(16)
            .size(48)

        badgeLabel.pin
            .top(12)
            .right(12)
            .height(20)
            .sizeToFit(.height)
            .marginLeft(8)
            .marginRight(8)
    }
}
