//
//  PetInfoSection.swift
//  Rewp
//
//  Created by 금가경 on 02/03/26.
//

import UIKit
import PinLayout
import Then

struct PetPolicy {
    let allowedTypes: [PetType]
    let sizeLimit: SizeLimit
    let maxCount: Int?
    let additionalDeposit: Int?

    enum PetType: String {
        case dog = "강아지"
        case cat = "고양이"
        case smallAnimal = "소동물"
    }

    enum SizeLimit: String {
        case smallOnly = "소형견만"
        case upToMedium = "중형견까지"
        case largePossible = "대형견 가능"
        case noLimit = "제한 없음"
    }
}

final class PetInfoSection: UIView {
    private let titleLabel = DetailTitle(title: "반려동물 정보")
    private let divider = ItemDivider()

    private let gridContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.borderColor = ColorSystem.gray30.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 20
    }

    private let allowedTypesTitle = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let allowedTypesValue = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let sizeLimitTitle = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let sizeLimitValue = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let maxCountTitle = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private let maxCountValue = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(divider)
        addSubview(titleLabel)
        addSubview(gridContainer)

        gridContainer.addSubview(allowedTypesTitle)
        gridContainer.addSubview(allowedTypesValue)
        gridContainer.addSubview(sizeLimitTitle)
        gridContainer.addSubview(sizeLimitValue)
        gridContainer.addSubview(maxCountTitle)
        gridContainer.addSubview(maxCountValue)
    }

    func configure(with policy: PetPolicy) {
        let typesText = policy.allowedTypes.map { $0.rawValue }.joined(separator: ", ")
        allowedTypesTitle.typography(FontSystem.Pretendard.caption1Semibold, text: "허용 동물")
        allowedTypesValue.typography(FontSystem.Pretendard.caption1Semibold, text: typesText)

        sizeLimitTitle.typography(FontSystem.Pretendard.caption1Semibold, text: "크기 제한")
        sizeLimitValue.typography(FontSystem.Pretendard.caption1Semibold, text: policy.sizeLimit.rawValue)

        let countText = policy.maxCount.map { "\($0)마리" } ?? "제한 없음"
        maxCountTitle.typography(FontSystem.Pretendard.caption1Semibold, text: "마릿수")
        maxCountValue.typography(FontSystem.Pretendard.caption1Semibold, text: countText)

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let horizontalMargin: CGFloat = 20
        let rowPadding: CGFloat = 16

        divider.pin
            .top()
            .horizontally()
            .sizeToFit(.width)

        titleLabel.pin
            .below(of: divider)
            .marginTop(5)
            .horizontally(horizontalMargin)
            .height(32)

        gridContainer.pin
            .below(of: titleLabel)
            .marginTop(8)
            .horizontally(horizontalMargin)

        allowedTypesTitle.pin
            .top(rowPadding)
            .left(rowPadding)
            .sizeToFit()

        allowedTypesValue.pin
            .top(rowPadding)
            .right(rowPadding)
            .sizeToFit()

        sizeLimitTitle.pin
            .below(of: allowedTypesTitle)
            .marginTop(rowPadding)
            .left(rowPadding)
            .sizeToFit()

        sizeLimitValue.pin
            .top(to: sizeLimitTitle.edge.top)
            .right(rowPadding)
            .sizeToFit()

        maxCountTitle.pin
            .below(of: sizeLimitTitle)
            .marginTop(rowPadding)
            .left(rowPadding)
            .sizeToFit()

        maxCountValue.pin
            .top(to: maxCountTitle.edge.top)
            .right(rowPadding)
            .sizeToFit()

        let gridHeight = maxCountValue.frame.maxY + rowPadding
        gridContainer.pin.height(gridHeight)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 188)
    }
}
