//
//  Divider.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then

final class NewsItemDivider: UIView {
    private let lineView = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorSystem.gray0
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(lineView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        lineView.pin
            .top(5)
            .horizontally(20)
            .height(1)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 11)
    }
}

@available(iOS 17.0, *)
#Preview {
    NewsItemDivider()
}
