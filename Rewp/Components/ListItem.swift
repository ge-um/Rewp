import UIKit
import PinLayout
import Then

final class ListItem: UIView {
    private let category: String
    private let title: String
    private let price: String
    private let area: String
    private let floor: String
    private let address: String
    private let showIcon: Bool

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let thumbnailView = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 8
    }

    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "Safty_Icon")
        $0.tintColor = ColorSystem.brightCoast
    }

    private lazy var categoryLabel = PaddingLabel().then {
        $0.textColor = ColorSystem.brightWood
        $0.typography(FontSystem.Pretendard.caption2, text: category)
        $0.backgroundColor = ColorSystem.brightCream
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.padding = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        $0.textAlignment = .center
    }

    private lazy var titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
        $0.typography(FontSystem.Pretendard.body2, text: title)
    }

    private lazy var priceLabel = UILabel().then {
        $0.textColor = ColorSystem.gray100
        $0.typography(FontSystem.Pretendard.body1, text: price)
    }

    private lazy var areaLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.typography(FontSystem.Pretendard.caption2, text: area)
    }

    private lazy var floorLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.typography(FontSystem.Pretendard.caption2, text: floor)
    }

    private lazy var addressLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.typography(FontSystem.Pretendard.caption2, text: address)
    }

    init(category: String, title: String, price: String, area: String, floor: String, address: String, showIcon: Bool = false) {
        self.category = category
        self.title = title
        self.price = price
        self.area = area
        self.floor = floor
        self.address = address
        self.showIcon = showIcon
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(thumbnailView)
        if showIcon {
            thumbnailView.addSubview(iconImageView)
        }
        containerView.addSubview(categoryLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(areaLabel)
        containerView.addSubview(floorLabel)
        containerView.addSubview(addressLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        thumbnailView.pin
            .left(20)
            .vCenter()
            .width(140)
            .height(108)

        if showIcon {
            iconImageView.pin
                .top(8)
                .left(8)
                .size(24)
        }

        categoryLabel.pin
            .after(of: thumbnailView)
            .marginLeft(12)
            .top(20)
            .sizeToFit(.widthFlexible)

        titleLabel.pin
            .after(of: categoryLabel)
            .marginLeft(4)
            .top(20)
            .right(20)
            .sizeToFit(.width)

        priceLabel.pin
            .after(of: thumbnailView)
            .marginLeft(12)
            .below(of: categoryLabel)
            .marginTop(6)
            .sizeToFit(.widthFlexible)

        areaLabel.pin
            .after(of: thumbnailView)
            .marginLeft(12)
            .below(of: priceLabel)
            .marginTop(6)
            .sizeToFit(.widthFlexible)

        floorLabel.pin
            .after(of: areaLabel)
            .marginLeft(8)
            .below(of: priceLabel)
            .marginTop(6)
            .sizeToFit(.widthFlexible)

        addressLabel.pin
            .after(of: thumbnailView)
            .marginLeft(12)
            .below(of: areaLabel)
            .marginTop(6)
            .right(20)
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 140)
    }
}

@available(iOS 17.0, *)
#Preview("Without Icon") {
    ListItem(
        category: "아파트",
        title: "문래동 롯데캐슬",
        price: "월세 3,000/120",
        area: "112.4m²",
        floor: "12층",
        address: "서울 영등포구 선유로9길 30"
    )
}

@available(iOS 17.0, *)
#Preview("With Icon") {
    ListItem(
        category: "아파트",
        title: "문래동 롯데캐슬",
        price: "월세 3,000/120",
        area: "112.4m²",
        floor: "12층",
        address: "서울 영등포구 선유로9길 30",
        showIcon: true
    )
}
