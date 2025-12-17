import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa

final class SortButton: UIControl {
    private let titleLabel = UILabel().then {
        $0.textAlignment = .center
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    private let title: String

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)

        layer.cornerRadius = 16
        layer.borderWidth = 1
    }

    private func updateAppearance() {
        if isSelected {
            layer.borderColor = ColorSystem.brightWood.cgColor
            titleLabel.textColor = ColorSystem.brightWood
        } else {
            layer.borderColor = ColorSystem.gray45.cgColor
            titleLabel.textColor = ColorSystem.gray75
        }

        titleLabel.typography(FontSystem.Pretendard.body2, text: title)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.pin
            .all(6.5)
            .sizeToFit(.width)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 76, height: 32)
    }
}

@available(iOS 17.0, *)
#Preview("Inactive") {
    SortButton(title: "Inactive")
}

@available(iOS 17.0, *)
#Preview("Active") {
    SortButton(title: "Active").then {
        $0.isSelected = true
    }
}
