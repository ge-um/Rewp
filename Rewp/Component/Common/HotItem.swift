//
//  HotItem.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then

final class HotItem: UIView {
    private let estateId: String
    private let imageURL: String?
    private let title: String
    private let price: String
    private let info: String

    var onTap: (() -> Void)?

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray45
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    private let overlayView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "Fire")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray0
    }

    private lazy var titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.typography(FontSystem.YeongdeokHaeparang.caption1, text: title)
        $0.textAlignment = .right
    }

    private lazy var priceLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.typography(FontSystem.Pretendard.body1, text: price)
        $0.textAlignment = .right
    }

    private lazy var infoLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.typography(FontSystem.Pretendard.caption2, text: info)
        $0.textAlignment = .right

    }

    init(estateId: String, imageURL: String? = nil, title: String, price: String, info: String) {
        self.estateId = estateId
        self.imageURL = imageURL
        self.title = title
        self.price = price
        self.info = info
        super.init(frame: .zero)
        setupUI()
        setupTapGesture()
        loadImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(overlayView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(infoLabel)
    }

    private func loadImage() {
        imageView.setImage(from: imageURL)
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        imageView.pin.all()
        overlayView.pin.all()

        iconImageView.pin
            .left(10)
            .top(10)
            .size(24)

        titleLabel.pin
            .top(10)
            .right(10)
            .sizeToFit(.widthFlexible)

        priceLabel.pin
            .below(of: titleLabel)
            .marginTop(4)
            .right(10)
            .sizeToFit(.widthFlexible)

        infoLabel.pin
            .below(of: priceLabel)
            .marginTop(4)
            .right(10)
            .sizeToFit(.widthFlexible)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 240, height: 88)
    }
}

final class PaddingLabel: UILabel {
    var padding = UIEdgeInsets.zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSize = super.sizeThatFits(CGSize(
            width: size.width - padding.left - padding.right,
            height: size.height - padding.top - padding.bottom
        ))
        return CGSize(
            width: superSize.width + padding.left + padding.right,
            height: superSize.height + padding.top + padding.bottom
        )
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: padding)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        return textRect.inset(by: UIEdgeInsets(
            top: -padding.top,
            left: -padding.left,
            bottom: -padding.bottom,
            right: -padding.right
        ))
    }
}

@available(iOS 17.0, *)
#Preview {
    HotItem(
        estateId: "1",
        imageURL: nil,
        title: "고즈넉 매물, 여기가 천국",
        price: "월세 3,000/20",
        info: "문래동 112.4m²"
    )
}
