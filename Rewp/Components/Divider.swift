import UIKit
import PinLayout

final class Divider: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = ColorSystem.gray15
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
}

@available(iOS 17.0, *)
#Preview {
    Divider()
}
