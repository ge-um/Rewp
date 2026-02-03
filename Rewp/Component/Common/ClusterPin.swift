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
    private let circleContainer = UIView().then {
        $0.backgroundColor = ColorSystem.deepCream.withAlphaComponent(0.8)
    }

    private let countLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
    }

    private let amenityContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 8
        $0.isHidden = true
    }

    private var amenityItemViews: [(container: UIView, emoji: UILabel, label: UILabel)] = []

    var count: Int = 0 {
        didSet {
            countLabel.typography(FontSystem.Pretendard.title1Bold, text: "\(count)")
        }
    }

    var amenityInfo: AmenityInfo? {
        didSet {
            updateAmenityViews()
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
        backgroundColor = .clear
        addSubview(circleContainer)
        addSubview(amenityContainer)
        circleContainer.addSubview(countLabel)
        countLabel.typography(FontSystem.Pretendard.title1Bold, text: "\(count)")
        createAmenityItemViews()
        updateAmenityViews()
    }

    private func createAmenityItemViews() {
        for _ in 0..<6 {
            let container = UIView()
            let emojiLabel = UILabel().then {
                $0.font = .systemFont(ofSize: 12)
                $0.textAlignment = .center
            }
            let countLabel = UILabel().then {
                $0.textColor = ColorSystem.gray75
                $0.textAlignment = .center
            }

            container.addSubview(emojiLabel)
            container.addSubview(countLabel)
            amenityContainer.addSubview(container)

            amenityItemViews.append((container, emojiLabel, countLabel))
        }
    }

    private func updateAmenityViews() {
        guard let amenityInfo = amenityInfo, !amenityInfo.isEmpty else {
            amenityContainer.isHidden = true
            return
        }

        amenityContainer.isHidden = false

        let items = amenityInfo.items
        let itemHeight: CGFloat = 14

        for (index, itemView) in amenityItemViews.enumerated() {
            if index < items.count {
                let (emoji, count) = items[index]
                itemView.emoji.text = emoji
                itemView.label.typography(FontSystem.Pretendard.caption1Medium, text: "\(count)")
                itemView.container.isHidden = false

                itemView.emoji.sizeToFit()
                itemView.label.sizeToFit()

                let emojiHeight = itemView.emoji.frame.height
                let labelHeight = itemView.label.frame.height
                let maxHeight = max(emojiHeight, labelHeight)

                itemView.emoji.frame.origin = CGPoint(x: 0, y: (maxHeight - emojiHeight) / 2)
                itemView.label.frame.origin = CGPoint(x: itemView.emoji.frame.width + 2, y: (maxHeight - labelHeight) / 2)

                let width = itemView.emoji.frame.width + 2 + itemView.label.frame.width
                itemView.container.frame.size = CGSize(width: width, height: itemHeight)
            } else {
                itemView.container.isHidden = true
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let circleDiameter = circleSize
        let totalWidth = intrinsicContentSize.width
        let centerX = totalWidth / 2

        circleContainer.pin
            .top()
            .left(centerX - circleDiameter / 2)
            .size(circleDiameter)

        circleContainer.layer.cornerRadius = circleDiameter / 2

        countLabel.pin
            .center()
            .sizeToFit()

        if !amenityContainer.isHidden {
            let visibleViews = amenityItemViews.filter { !$0.container.isHidden }
            var totalWidth: CGFloat = 0
            for (index, itemView) in visibleViews.enumerated() {
                totalWidth += itemView.container.frame.width
                if index < visibleViews.count - 1 {
                    totalWidth += 8
                }
            }

            let amenityWidth = totalWidth + 16
            let amenityHeight: CGFloat = 24
            let itemHeight: CGFloat = 14

            amenityContainer.pin
                .below(of: circleContainer)
                .marginTop(4)
                .left(centerX - amenityWidth / 2)
                .width(amenityWidth)
                .height(amenityHeight)

            var currentX: CGFloat = 8
            for itemView in visibleViews {
                itemView.container.frame.origin = CGPoint(x: currentX, y: (amenityHeight - itemHeight) / 2)
                currentX += itemView.container.frame.width + 8
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        let circleDiameter = circleSize
        var totalHeight = circleDiameter

        if let amenityInfo = amenityInfo, !amenityInfo.isEmpty {
            totalHeight += 4 + 24
        }

        let amenityWidth = calculateAmenityWidth()
        let width = max(circleDiameter, amenityWidth)

        return CGSize(width: width, height: totalHeight)
    }

    private var circleSize: CGFloat {
        let digitCount = "\(count)".count
        switch digitCount {
        case 1:
            return 36
        case 2:
            return 56
        case 3:
            return 76
        default:
            return 100
        }
    }


    private func calculateAmenityWidth() -> CGFloat {
        guard let amenityInfo = amenityInfo, !amenityInfo.isEmpty else {
            return 0
        }

        var totalWidth: CGFloat = 16
        for (index, item) in amenityInfo.items.enumerated() {
            let emojiWidth = (item.emoji as NSString).size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 12)
            ]).width

            let countText = "\(item.count)"
            let countWidth = (countText as NSString).size(withAttributes: [
                .font: FontSystem.Pretendard.caption1Medium.font
            ]).width

            totalWidth += emojiWidth + 2 + countWidth

            if index < amenityInfo.items.count - 1 {
                totalWidth += 8
            }
        }

        return totalWidth
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

@available(iOS 17.0, *)
#Preview("amenity 있음") {
    ClusterPin(
        count: 42,
        amenityInfo: AmenityInfo(
            parks: 2,
            mountains: 1,
            rivers: 0,
            veterinary: 1,
            cafes: 3,
            playgrounds: 0
        )
    )
}
