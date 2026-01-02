//
//  Divider.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import Then

final class ItemDivider: UIView {
    private let lineView = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
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
    ItemDivider()
}
