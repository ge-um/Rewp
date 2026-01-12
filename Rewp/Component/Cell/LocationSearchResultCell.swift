//
//  LocationSearchResultCell.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import UIKit
import PinLayout
import FlexLayout
import Then

final class LocationSearchResultCell: UITableViewCell, IsIdentifiable {
    private let containerView = UIView()

    private let iconView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let addressLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .default
        backgroundColor = ColorSystem.gray0
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)

        containerView.flex
            .direction(.row)
            .alignItems(.center)
            .paddingHorizontal(20)
            .define { flex in
                flex.addItem(iconView)
                    .size(24)
                    .marginRight(12)

                flex.addItem(addressLabel)
                    .grow(1)
            }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin
            .all()

        containerView.flex.layout()
    }

    func configure(with result: SearchResult) {
        addressLabel.typography(FontSystem.Pretendard.body1, text: result.address)

        switch result.type {
        case .address:
            iconView.image = UIImage(systemName: "mappin.circle.fill")
            iconView.tintColor = ColorSystem.brightCream
        case .subway:
            iconView.image = UIImage(systemName: "train.side.front.car")
            iconView.tintColor = ColorSystem.brightCoast
        case .university:
            iconView.image = UIImage(systemName: "building.columns.fill")
            iconView.tintColor = ColorSystem.brightWood
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.pin.width(size.width)
        containerView.pin.all()
        containerView.flex.layout(mode: .adjustHeight)
        return CGSize(width: size.width, height: 64)
    }
}
