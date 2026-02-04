//
//  NewsAdItem.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then

final class NewsAdItem: UIView {
    private let payloadType: String?
    private let payloadValue: String?

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.06
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let textContainerView = UIView()

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    private let descriptionLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let calendarImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "calendar")
    }

    var onTap: (() -> Void)?

    init(title: String, description: String, payloadType: String? = nil, payloadValue: String? = nil) {
        self.payloadType = payloadType
        self.payloadValue = payloadValue
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body1, text: title)
        descriptionLabel.typography(FontSystem.Pretendard.caption1Regular, text: description)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textContainerView)
        containerView.addSubview(calendarImageView)

        textContainerView.addSubview(titleLabel)
        textContainerView.addSubview(descriptionLabel)

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        onTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        calendarImageView.pin
            .right(20)
            .vCenter()
            .size(80)

        textContainerView.pin
            .left(20)
            .before(of: calendarImageView)
            .marginRight(12)
            .vCenter()

        titleLabel.pin
            .top()
            .horizontally()
            .sizeToFit(.width)

        descriptionLabel.pin
            .below(of: titleLabel)
            .marginTop(4)
            .horizontally()
            .sizeToFit(.width)

        textContainerView.pin
            .wrapContent(.vertically)
            .vCenter()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 96)
    }
}

@available(iOS 17.0, *)
#Preview {
    NewsAdItem(
        title: "배너 광고 타이틀 문구",
        description: "배너 광고 설명 서브타이틀 문구"
    )
}
