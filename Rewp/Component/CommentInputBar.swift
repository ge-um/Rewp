//
//  CommentInputBar.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import PinLayout
import Then
import RxSwift
import RxCocoa

final class CommentInputBar: UIView {
    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: -2)
        $0.layer.shadowRadius = 8
    }

    private let textContainerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 20
    }

    private let textView = UITextView().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = .clear
        $0.isScrollEnabled = false
        $0.textContainerInset = .zero
        $0.textContainer.lineFragmentPadding = 0
    }

    private let placeholderLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.typography(FontSystem.Pretendard.body2, text: "댓글을 입력하세요")
    }

    private let sendButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        $0.tintColor = ColorSystem.brightCoast
        $0.isEnabled = false
    }

    private let disposeBag = DisposeBag()

    private var cachedTextHeight: CGFloat?
    private var cachedAvailableWidth: CGFloat?

    var sendButtonTapped: Observable<Void> {
        return sendButton.rx.tap.asObservable()
    }

    var textInput: Observable<String> {
        return textView.rx.text.orEmpty.asObservable()
    }

    var text: String {
        get { textView.text ?? "" }
        set { textView.text = newValue; updatePlaceholder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(textContainerView)
        textContainerView.addSubview(textView)
        textContainerView.addSubview(placeholderLabel)
        containerView.addSubview(sendButton)
    }

    private func bind() {
        textView.rx.text.orEmpty
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.placeholderLabel.isHidden = !text.isEmpty
                owner.sendButton.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                owner.cachedTextHeight = nil
                owner.invalidateIntrinsicContentSize()
                owner.setNeedsLayout()
                owner.superview?.setNeedsLayout()
                owner.layoutIfNeeded()
                owner.superview?.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
    }

    private func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        sendButton.isEnabled = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setPlaceholder(_ text: String) {
        placeholderLabel.typography(FontSystem.Pretendard.body2, text: text)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all()
        containerView.layer.shadowPath = UIBezierPath(rect: containerView.bounds).cgPath

        sendButton.pin
            .right(16)
            .vCenter()
            .size(36)

        textContainerView.pin
            .left(16)
            .before(of: sendButton)
            .marginRight(8)
            .vCenter()

        let padding: CGFloat = 12
        let textWidth = textContainerView.bounds.width - padding * 2

        if cachedTextHeight == nil || cachedAvailableWidth != textWidth {
            let textSize = textView.sizeThatFits(
                CGSize(width: textWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextHeight = max(textSize.height, 20)
            cachedAvailableWidth = textWidth
        }

        let textHeight = cachedTextHeight!
        let containerHeight = textHeight + padding * 2
        let finalHeight = min(containerHeight, 100)

        textView.isScrollEnabled = containerHeight > 100

        textContainerView.pin
            .height(finalHeight)

        textView.pin
            .horizontally(padding)
            .vCenter()
            .height(min(textHeight, 100 - padding * 2))

        placeholderLabel.pin
            .left(padding)
            .vCenter()
            .sizeToFit()
    }

    override var intrinsicContentSize: CGSize {
        let screenWidth = superview?.bounds.width ?? UIScreen.main.bounds.width
        let padding: CGFloat = 12
        let availableWidth = screenWidth - 16 - 8 - 36 - 16 - padding * 2

        if cachedTextHeight == nil || cachedAvailableWidth != availableWidth {
            let textSize = textView.sizeThatFits(
                CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextHeight = max(textSize.height, 20)
            cachedAvailableWidth = availableWidth
        }

        let textHeight = cachedTextHeight!
        let containerHeight = textHeight + padding * 2
        let finalHeight = min(containerHeight, 100)
        return CGSize(width: UIView.noIntrinsicMetric, height: finalHeight + 16 + pin.safeArea.bottom)
    }

    func clearText() {
        textView.text = ""
        updatePlaceholder()
        cachedTextHeight = nil
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        superview?.setNeedsLayout()
        layoutIfNeeded()
        superview?.layoutIfNeeded()
    }

    func focusInput() {
        textView.becomeFirstResponder()
    }
}
