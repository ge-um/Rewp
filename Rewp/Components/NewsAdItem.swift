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
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
    }

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    private let descriptionLabel = UILabel().then {
        $0.textColor = ColorSystem.gray45
    }

    init(title: String, description: String) {
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body2, text: title)
        descriptionLabel.typography(FontSystem.Pretendard.caption2, text: description)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        titleLabel.pin
            .top(16.5)
            .horizontally(20)
            .sizeToFit(.width)

        descriptionLabel.pin
            .below(of: titleLabel)
            .marginTop(4)
            .horizontally(20)
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 66)
    }
}

@available(iOS 17.0, *)
#Preview {
    NewsAdItem(
        title: "배너 광고 타이틀 문구",
        description: "배너 광고 설명 서브타이틀 문구"
    )
}
