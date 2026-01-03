//
//  ChatMessageCell.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import PinLayout
import Then

final class ChatMessageCell: UITableViewCell, IsIdentifiable {
    private let containerView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let bubbleView = UIView().then {
        $0.backgroundColor = ColorSystem.brightCoast
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

    private let messageLabel = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.numberOfLines = 0
    }

    private let timeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private var cachedTextSize: CGSize?
    private var cachedMaxWidth: CGFloat?
    private var cachedContent: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxBubbleWidth = contentView.bounds.width * 0.65
        let padding: CGFloat = 12

        containerView.pin.all()

        if cachedTextSize == nil || cachedMaxWidth != maxBubbleWidth {
            let maxTextWidth = maxBubbleWidth - padding * 2
            let textSize = messageLabel.sizeThatFits(
                CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextSize = textSize
            cachedMaxWidth = maxBubbleWidth
        }

        let textSize = cachedTextSize!
        let bubbleWidth = textSize.width + padding * 2
        let bubbleHeight = textSize.height + padding * 2

        bubbleView.pin
            .top(8)
            .right(16)
            .width(bubbleWidth)
            .height(bubbleHeight)

        messageLabel.pin
            .top(padding)
            .left(padding)
            .width(textSize.width)
            .height(textSize.height)

        timeLabel.pin
            .before(of: bubbleView, aligned: .bottom)
            .marginRight(8)
            .sizeToFit()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxBubbleWidth = size.width * 0.65
        let padding: CGFloat = 12

        if cachedTextSize == nil || cachedMaxWidth != maxBubbleWidth {
            let maxTextWidth = maxBubbleWidth - padding * 2
            let textSize = messageLabel.sizeThatFits(
                CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextSize = textSize
            cachedMaxWidth = maxBubbleWidth
        }

        let bubbleHeight = cachedTextSize!.height + padding * 2
        return CGSize(width: size.width, height: bubbleHeight + 16)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cachedTextSize = nil
        cachedMaxWidth = nil
        cachedContent = nil
    }

    func configure(with message: ChatMessage) {
        if cachedContent != message.content {
            cachedTextSize = nil
            cachedContent = message.content
        }

        messageLabel.typography(FontSystem.Pretendard.body2, text: message.content)
        timeLabel.typography(FontSystem.Pretendard.caption2, text: formatTime(message.createdAt))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
