import UIKit
import PinLayout
import Then

final class CategoryButton: UIView {
    private let iconContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 16
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
        $0.textAlignment = .center
    }

    init(icon: UIImage?, title: String) {
        super.init(frame: .zero)
        iconImageView.image = icon
        titleLabel.typography(FontSystem.Pretendard.body3, text: title)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        iconContainer.pin
            .top()
            .hCenter()
            .size(56)

        iconImageView.pin
            .center()
            .size(32)

        titleLabel.pin
            .below(of: iconContainer)
            .marginTop(8)
            .horizontally()
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 64, height: 88)
    }
}

@available(iOS 17.0, *)
#Preview("원룸") {
    CategoryButton(icon: UIImage(named: "OneRoom"), title: "원룸")
}

@available(iOS 17.0, *)
#Preview("오피스텔") {
    CategoryButton(icon: UIImage(named: "Officetel"), title: "오피스텔")
}

@available(iOS 17.0, *)
#Preview("아파트") {
    CategoryButton(icon: UIImage(named: "Apartment"), title: "아파트")
}

@available(iOS 17.0, *)
#Preview("빌라") {
    CategoryButton(icon: UIImage(named: "Villa"), title: "빌라")
}

@available(iOS 17.0, *)
#Preview("상가") {
    CategoryButton(icon: UIImage(named: "Storefront"), title: "상가")
}
