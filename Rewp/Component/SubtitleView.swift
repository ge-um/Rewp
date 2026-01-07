//
//  SubtitleView.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import PinLayout
import Then

final class SubtitleView: UIView {
    private let textLabel = UILabel().then {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
    }

    private let padding: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(textLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String?) {
        textLabel.typography(FontSystem.Pretendard.body1, text: text ?? "")
        textLabel.isHidden = text == nil
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxWidth = bounds.width - (padding * 2)
        let textSize = textLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))

        textLabel.pin
            .hCenter()
            .bottom()
            .marginBottom(20)
            .width(textSize.width + (padding * 2))
            .height(textSize.height + (padding * 2))
    }
}
