//
//  MapBubbleButton.swift
//  Rewp
//
//  Created by 금가경 on 12/17/25.
//

import UIKit
import PinLayout
import Then

final class MapBubbleButton: UIView {
    private let bubbleView = UIView()

    private let propertyImageView = UIImageView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 4
    }

    private let countLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
        $0.textAlignment = .center
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.borderColor = ColorSystem.gray30.withAlphaComponent(0.3).cgColor
        $0.layer.borderWidth = 1
        $0.clipsToBounds = true
    }

    private let subNumberLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.textAlignment = .left
    }

    var propertyImage: UIImage? {
        didSet {
            propertyImageView.image = propertyImage
        }
    }

    var count: Int = 0 {
        didSet {
            countLabel.typography(FontSystem.Pretendard.body3Bold, text: "\(count)")
        }
    }

    var subNumbers: (deposit: Int, rent: Int) = (0, 0) {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let depositStr = formatter.string(from: NSNumber(value: subNumbers.deposit)) ?? "\(subNumbers.deposit)"
            let rentStr = formatter.string(from: NSNumber(value: subNumbers.rent)) ?? "\(subNumbers.rent)"
            subNumberLabel.typography(FontSystem.Pretendard.caption2Semibold, text: "\(depositStr)/\(rentStr)")
        }
    }

    init(count: Int, subNumbers: (deposit: Int, rent: Int), propertyImage: UIImage? = nil) {
        super.init(frame: .zero)
        self.count = count
        self.subNumbers = subNumbers
        self.propertyImage = propertyImage
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(bubbleView)
        addSubview(countLabel)

        bubbleView.addSubview(propertyImageView)
        bubbleView.addSubview(subNumberLabel)

        countLabel.typography(FontSystem.Pretendard.body3Bold, text: "\(count)")

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let depositStr = formatter.string(from: NSNumber(value: subNumbers.deposit)) ?? "\(subNumbers.deposit)"
        let rentStr = formatter.string(from: NSNumber(value: subNumbers.rent)) ?? "\(subNumbers.rent)"
        subNumberLabel.typography(FontSystem.Pretendard.caption2Semibold, text: "\(depositStr)/\(rentStr)")

        propertyImageView.image = propertyImage
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bubbleHeight: CGFloat = 96
        let countCircleSize: CGFloat = 28
        let padding: CGFloat = 4

        bubbleView.pin
            .top()
            .horizontally()
            .height(bubbleHeight)

        propertyImageView.pin
            .top(padding)
            .hCenter()
            .size(64)

        subNumberLabel.pin
            .below(of: propertyImageView)
            .marginTop(4)
            .left(6)
            .right()
            .sizeToFit(.width)

        countLabel.pin
            .top(-10)
            .right(-10)
            .size(countCircleSize)

        countLabel.layer.cornerRadius = countCircleSize / 2
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let bubbleHeight: CGFloat = 87
        let tailHeight: CGFloat = 8
        let tailWidth: CGFloat = 12
        let cornerRadius: CGFloat = 8

        let path = UIBezierPath()

        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: cornerRadius),
                         controlPoint: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: bubbleHeight - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.width - cornerRadius, y: bubbleHeight),
                         controlPoint: CGPoint(x: rect.width, y: bubbleHeight))

        let tailCenter = rect.width / 2
        path.addLine(to: CGPoint(x: tailCenter + tailWidth / 2, y: bubbleHeight))
        path.addLine(to: CGPoint(x: tailCenter, y: bubbleHeight + tailHeight))
        path.addLine(to: CGPoint(x: tailCenter - tailWidth / 2, y: bubbleHeight))

        path.addLine(to: CGPoint(x: cornerRadius, y: bubbleHeight))
        path.addQuadCurve(to: CGPoint(x: 0, y: bubbleHeight - cornerRadius),
                         controlPoint: CGPoint(x: 0, y: bubbleHeight))
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                         controlPoint: CGPoint(x: 0, y: 0))
        path.close()

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 4),
            blur: 12,
            color: UIColor(red: 82/255, green: 81/255, blue: 86/255, alpha: 0.2).cgColor
        )
        ColorSystem.gray0.setFill()
        path.fill()
        context.restoreGState()

        ColorSystem.gray30.withAlphaComponent(0.2).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 72, height: 100)
    }

    func configure(count: Int, subNumbers: (deposit: Int, rent: Int), imageURL: URL?) {
        self.count = count
        self.subNumbers = subNumbers
        if let url = imageURL {
            propertyImageView.kf.setImage(with: url)
        }
    }
}

@available(iOS 17.0, *)
#Preview("기본") {
    MapBubbleButton(count: 4, subNumbers: (deposit: 3000, rent: 120))
}

@available(iOS 17.0, *)
#Preview("다른 숫자") {
    MapBubbleButton(count: 12, subNumbers: (deposit: 5000, rent: 250))
}
