//
//  RecentSearchItem.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import UIKit
import FlexLayout
import PinLayout
import Then

final class RecentSearchItem: UIView {
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = ColorSystem.gray30.cgColor
        $0.layer.shadowColor = ColorSystem.shadow.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 4)
        $0.layer.shadowRadius = 6
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = ColorSystem.gray15
    }

    private let recommendBadge = UILabel().then {
        $0.textColor = ColorSystem.brightWood
        $0.backgroundColor = ColorSystem.brightCream.withAlphaComponent(0.4)
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.textAlignment = .center
    }

    private let categoryLabel = UILabel().then {
        $0.textColor = ColorSystem.deepWood
    }

    private var hasRecommend = false

    private let priceLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let areaLabel = UILabel().then {
        $0.textColor = ColorSystem.gray45
    }

    init(recommend: String? = nil, category: String, price: String, area: String, image: UIImage? = nil) {
        super.init(frame: .zero)

        if let recommend = recommend {
            hasRecommend = true
            recommendBadge.typography(FontSystem.Pretendard.caption3, text: recommend)
        }

        categoryLabel.typography(FontSystem.Pretendard.caption2, text: category)
        priceLabel.typography(FontSystem.Pretendard.body3, text: price)
        areaLabel.typography(FontSystem.Pretendard.caption1Semibold, text: area)
        thumbnailImageView.image = image
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)

        containerView.flex
            .direction(.row)
            .padding(12)
            .alignItems(.center)
            .define { flex in
                flex.addItem(thumbnailImageView)
                    .width(64)
                    .height(64)
                    .marginRight(12)

                flex.addItem()
                    .direction(.column)
                    .justifyContent(.center)
                    .grow(1)
                    .define { flex in
                        flex.addItem()
                            .direction(.row)
                            .marginBottom(4)
                            .define { flex in
                                if hasRecommend {
                                    flex.addItem(recommendBadge)
                                        .width(24)
                                        .height(14)
                                        .marginRight(4)
                                }
                                flex.addItem(categoryLabel)
                            }

                        flex.addItem(priceLabel).marginBottom(4)
                        flex.addItem(areaLabel)
                    }
            }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.pin.all()
        containerView.flex.layout()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 190, height: 88)
    }
}

@available(iOS 17.0, *)
#Preview("추천 있음") {
    RecentSearchItem(
        recommend: "추천",
        category: "원룸",
        price: "전세 3,000/20",
        area: "면적 49.5m²",
        image: nil
    )
}

@available(iOS 17.0, *)
#Preview("추천 없음") {
    RecentSearchItem(
        category: "원룸",
        price: "월세 3,000/50",
        area: "면적 112.4m²",
        image: nil
    )
}
