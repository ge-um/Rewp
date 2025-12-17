import UIKit
import PinLayout
import Then

final class RecentSearchItem: UIView {
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = ColorSystem.gray100.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
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
        $0.isHidden = true
    }

    private let typeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    private let priceLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let areaLabel = UILabel().then {
        $0.textColor = ColorSystem.gray45
    }

    init(recommend: String?, type: String, price: String, area: String, image: UIImage? = nil) {
        super.init(frame: .zero)
        if recommend != nil {
            recommendBadge.typography(FontSystem.Pretendard.caption3, text: "추천")
            recommendBadge.isHidden = false
        }
        typeLabel.typography(FontSystem.Pretendard.caption2, text: type)
        priceLabel.typography(FontSystem.Pretendard.body3, text: price)
        areaLabel.typography(FontSystem.Pretendard.caption1, text: area)
        thumbnailImageView.image = image
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(recommendBadge)
        containerView.addSubview(typeLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(areaLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        thumbnailImageView.pin
            .left(12)
            .vCenter()
            .size(68)

        if !recommendBadge.isHidden {
            recommendBadge.pin
                .after(of: thumbnailImageView)
                .marginLeft(12)
                .top(thumbnailImageView.frame.minY)
                .width(24)
                .height(14)

            typeLabel.pin
                .after(of: recommendBadge)
                .marginLeft(4)
                .vCenter(to: recommendBadge.edge.vCenter)
                .sizeToFit()
        } else {
            typeLabel.pin
                .after(of: thumbnailImageView)
                .marginLeft(12)
                .top(thumbnailImageView.frame.minY)
                .sizeToFit()
        }

        priceLabel.pin
            .after(of: thumbnailImageView)
            .marginLeft(12)
            .below(of: recommendBadge.isHidden ? typeLabel : recommendBadge)
            .marginTop(8)
            .right(12)
            .sizeToFit(.width)

        areaLabel.pin
            .after(of: thumbnailImageView)
            .marginLeft(12)
            .below(of: priceLabel)
            .marginTop(8)
            .right(12)
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 190, height: 88)
    }
}

@available(iOS 17.0, *)
#Preview("추천 있음") {
    RecentSearchItem(
        recommend: "추천",
        type: "분리형 원룸",
        price: "월세 3,000/20",
        area: "면적 112.4m²",
        image: nil
    )
}

@available(iOS 17.0, *)
#Preview("추천 없음") {
    RecentSearchItem(
        recommend: nil,
        type: "분리형 원룸",
        price: "월세 3,000/20",
        area: "면적 112.4m²",
        image: nil
    )
}
