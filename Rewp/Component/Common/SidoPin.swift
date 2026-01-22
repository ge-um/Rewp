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
    private let circleContainer = UIView().then {
        $0.backgroundColor = ColorSystem.deepCream
    }

    private let nameLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
    }

    private let countLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.textAlignment = .center
    }

    private let sidoName: String
    private let estateCount: Int

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
        addSubview(circleContainer)
        circleContainer.addSubview(nameLabel)
        circleContainer.addSubview(countLabel)

        nameLabel.typography(FontSystem.Pretendard.caption1Medium, text: sidoName)
        countLabel.typography(FontSystem.Pretendard.title1Bold, text: "\(estateCount)")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let diameter = circleSize
        circleContainer.pin
            .center()
            .size(diameter)
        circleContainer.layer.cornerRadius = diameter / 2

        nameLabel.pin
            .top(diameter * 0.2)
            .hCenter()
            .sizeToFit()

        countLabel.pin
            .below(of: nameLabel)
            .marginTop(2)
            .hCenter()
            .sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        let diameter = circleSize
        return CGSize(width: diameter, height: diameter)
    }

    private var circleSize: CGFloat {
        switch estateCount {
        case 0..<100:
            return 56
        case 100..<500:
            return 68
        case 500..<1000:
            return 80
        default:
            return 92
        }
    }
}
