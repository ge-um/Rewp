//
//  NewsHashTagItem.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then

final class NewsHashTagItem: UIView {
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let titleLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray90
    }

    private let descriptionLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray60
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let dateLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray75
    }

    var onTap: (() -> Void)?

    init(hashtag: String, description: String, date: String) {
        super.init(frame: .zero)
        titleLabel.text = hashtag
        descriptionLabel.text = description
        dateLabel.text = date
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(dateLabel)

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

        dateLabel.pin
            .top(24.5)
            .right(20)
            .sizeToFit()

        titleLabel.pin
            .top(12)
            .left(20)
            .before(of: dateLabel)
            .marginRight(12)
            .sizeToFit(.width)

        descriptionLabel.pin
            .bottom(12)
            .left(20)
            .before(of: dateLabel)
            .marginRight(12)
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 66)
    }
}

@available(iOS 17.0, *)
#Preview {
    NewsHashTagItem(
        hashtag: "#뉴스 해쉬태그",
        description: "해쉬태그에 대한 뉴스 세부 기사, 내용",
        date: "25. 4. 4"
    )
}
