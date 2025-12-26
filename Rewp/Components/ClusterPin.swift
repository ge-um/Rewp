//
//  ClusterPin.swift
//  Rewp
//
//  Created by 금가경 on 12/17/25.
//

import UIKit
import PinLayout
import Then

final class ClusterPin: UIView {
    private let countLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
    }

    var count: Int = 0 {
        didSet {
            countLabel.typography(FontSystem.Pretendard.body2, text: "\(count)")
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }

    init(count: Int) {
        super.init(frame: .zero)
        self.count = count
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.deepCream
        addSubview(countLabel)
        countLabel.typography(FontSystem.Pretendard.title1, text: "\(count)")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = intrinsicContentSize
        layer.cornerRadius = size.width / 2

        countLabel.pin
            .center()
            .sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        let digitCount = "\(count)".count
        let diameter: CGFloat

        switch digitCount {
        case 1:
            diameter = 40
        case 2:
            diameter = 50
        default:
            diameter = 60
        }

        return CGSize(width: diameter, height: diameter)
    }
}

@available(iOS 17.0, *)
#Preview("1글자") {
    ClusterPin(count: 5)
}

@available(iOS 17.0, *)
#Preview("2글자") {
    ClusterPin(count: 42)
}

@available(iOS 17.0, *)
#Preview("3글자") {
    ClusterPin(count: 123)
}
