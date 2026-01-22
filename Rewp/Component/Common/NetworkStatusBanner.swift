//
//  NetworkStatusBanner.swift
//  Rewp
//
//  Created by 금가경 on 01/18/26.
//

import UIKit
import PinLayout
import Then

final class NetworkStatusBanner: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "wifi.slash")
        $0.tintColor = ColorSystem.gray0
        $0.contentMode = .scaleAspectFit
    }

    private let messageLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.text = "네트워크가 불안정해요"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.gray60
        addSubview(iconImageView)
        addSubview(messageLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        iconImageView.pin
            .left(16)
            .vCenter()
            .size(20)

        messageLabel.pin
            .after(of: iconImageView)
            .marginLeft(8)
            .right(16)
            .vCenter()
            .sizeToFit(.width)

        messageLabel.typography(FontSystem.Pretendard.body2)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 36)
    }
}
