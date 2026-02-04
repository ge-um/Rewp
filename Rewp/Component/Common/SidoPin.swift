//
//  SidoPin.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import UIKit
import PinLayout
import Then

final class SidoPin: UIView {
    private let countPill = UIView().then {
        $0.backgroundColor = ColorSystem.deepCream
    }

    private let namePill = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 14
        $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }

    private let countLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
    }

    private let nameLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
        $0.textAlignment = .center
    }

    private let sidoName: String
    private let estateCount: Int
    private let pillHeight: CGFloat = 28
    private let countPaddingH: CGFloat = 10
    private let namePaddingLeft: CGFloat = 20
    private let namePaddingRight: CGFloat = 8
    private let overlap: CGFloat = 16

    init(name: String, count: Int) {
        self.sidoName = name
        self.estateCount = count
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(namePill)
        addSubview(countPill)
        countPill.addSubview(countLabel)
        namePill.addSubview(nameLabel)

        countLabel.typography(FontSystem.Pretendard.body2Bold, text: "\(estateCount)")
        nameLabel.typography(FontSystem.Pretendard.caption1Medium, text: sidoName)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let countWidth = countLabelSize.width + countPaddingH * 2
        let nameWidth = nameLabelSize.width + namePaddingLeft + namePaddingRight

        countPill.pin
            .left()
            .vCenter()
            .width(countWidth)
            .height(pillHeight)
        countPill.layer.cornerRadius = 14

        countLabel.pin
            .center()
            .sizeToFit()

        namePill.pin
            .after(of: countPill, aligned: .center)
            .marginLeft(-overlap)
            .width(nameWidth)
            .height(pillHeight)

        nameLabel.pin
            .vCenter()
            .left(namePaddingLeft)
            .sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        let countWidth = countLabelSize.width + countPaddingH * 2
        let nameWidth = nameLabelSize.width + namePaddingLeft + namePaddingRight
        let totalWidth = countWidth + nameWidth - overlap
        return CGSize(width: totalWidth, height: pillHeight)
    }

    private var countLabelSize: CGSize {
        let text = "\(estateCount)" as NSString
        return text.size(withAttributes: [.font: FontSystem.Pretendard.body2Bold.font])
    }

    private var nameLabelSize: CGSize {
        let text = sidoName as NSString
        return text.size(withAttributes: [.font: FontSystem.Pretendard.caption1Medium.font])
    }
}

@available(iOS 17.0, *)
#Preview("1자리") {
    SidoPin(name: "제주도", count: 6)
}

@available(iOS 17.0, *)
#Preview("2자리") {
    SidoPin(name: "강원도", count: 71)
}

@available(iOS 17.0, *)
#Preview("3자리") {
    SidoPin(name: "인천", count: 645)
}

@available(iOS 17.0, *)
#Preview("4자리") {
    SidoPin(name: "경상남도", count: 2217)
}

@available(iOS 17.0, *)
#Preview("5자리") {
    SidoPin(name: "대구", count: 11758)
}
