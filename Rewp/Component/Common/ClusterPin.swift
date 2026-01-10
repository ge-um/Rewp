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

    private let amenityLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
        $0.isHidden = true
    }

    var count: Int = 0 {
        didSet {
            countLabel.typography(FontSystem.Pretendard.body2, text: "\(count)")
        }
    }

    var amenityInfo: AmenityInfo? {
        didSet {
            if let amenityInfo = amenityInfo, !amenityInfo.isEmpty {
                amenityLabel.typography(FontSystem.Pretendard.caption1Medium, text: amenityInfo.displayText())
                amenityLabel.isHidden = false
            } else {
                amenityLabel.isHidden = true
            }
        }
    }

    init(count: Int, amenityInfo: AmenityInfo? = nil) {
        super.init(frame: .zero)
        self.count = count
        self.amenityInfo = amenityInfo
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.deepCream
        addSubview(countLabel)
        addSubview(amenityLabel)
        countLabel.typography(FontSystem.Pretendard.title1Bold, text: "\(count)")

        if let amenityInfo = amenityInfo, !amenityInfo.isEmpty {
            amenityLabel.typography(FontSystem.Pretendard.caption1Medium, text: amenityInfo.displayText())
            amenityLabel.isHidden = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = intrinsicContentSize
        layer.cornerRadius = size.width / 2

        if let amenityInfo = amenityInfo, !amenityInfo.isEmpty {
            countLabel.pin
                .hCenter()
                .top(10)
                .sizeToFit()

            amenityLabel.pin
                .below(of: countLabel)
                .marginTop(2)
                .hCenter()
                .sizeToFit()
        } else {
            countLabel.pin
                .center()
                .sizeToFit()
        }
    }

    override var intrinsicContentSize: CGSize {
        let digitCount = "\(count)".count
        var diameter: CGFloat

        switch digitCount {
        case 1, 2:
            diameter = 52
        default:
            diameter = 80
        }

        if let amenityInfo = amenityInfo, !amenityInfo.isEmpty {
            diameter += 24
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
