//
//  PlaceholderTextView.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import PinLayout

final class PlaceholderTextView: UITextView {

    private let placeholderLabel = UILabel()

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    var placeholderColor: UIColor = ColorSystem.gray45 {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
        setupDesign()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
        setupDesign()
    }

    private func setupDesign() {
        backgroundColor = ColorSystem.gray0
        textColor = ColorSystem.gray90
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = ColorSystem.gray45.cgColor
        textContainerInset = UIEdgeInsets(top: 14, left: 11, bottom: 12, right: 11)
        isScrollEnabled = false
        font = FontSystem.Pretendard.body2.font
    }

    private func setupPlaceholder() {
        addSubview(placeholderLabel)
        placeholderLabel.font = FontSystem.Pretendard.body2.font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.numberOfLines = 0

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        updatePlaceholderVisibility()
    }

    @objc private func textDidChange() {
        updatePlaceholderVisibility()
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderLabel.pin
            .top(textContainerInset.top)
            .left(textContainerInset.left + textContainer.lineFragmentPadding)
            .right(textContainerInset.right + textContainer.lineFragmentPadding)
            .sizeToFit(.width)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
