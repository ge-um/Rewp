import UIKit
import PinLayout
import Then

final class SearchBar: UIView {
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = ColorSystem.gray100.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(named: "Search")?.withRenderingMode(.alwaysTemplate)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = ColorSystem.gray45
    }

    private let textField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "검색어를 입력해주세요")
        $0.textColor = ColorSystem.gray90
        $0.clearButtonMode = .whileEditing
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(textField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()

        iconImageView.pin
            .left(16)
            .vCenter()
            .size(24)

        textField.pin
            .after(of: iconImageView)
            .marginLeft(8)
            .right(16)
            .vCenter()
            .height(24)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
}

@available(iOS 17.0, *)
#Preview {
    let searchBar = SearchBar()
    return searchBar
}
