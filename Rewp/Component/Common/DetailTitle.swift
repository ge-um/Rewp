//
//  DetailTitle.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import UIKit
import PinLayout
import Then

final class DetailTitle: UIView {
    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.typography(FontSystem.Pretendard.body2Bold, text: title)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.pin
            .left()
            .vCenter()
            .sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 32)
    }
}

@available(iOS 17.0, *)
#Preview {
    DetailTitle(title: "옵션 정보")
}
