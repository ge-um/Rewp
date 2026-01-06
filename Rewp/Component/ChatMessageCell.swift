//
//  ChatMessageCell.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import OSLog
import PinLayout
import FlexLayout
import Then
import Kingfisher

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

    private let sendingIndicator = UIImageView().then {
        $0.image = UIImage(systemName: "paperplane.fill")
        $0.tintColor = ColorSystem.gray60
        $0.isHidden = true
        $0.transform = CGAffineTransform(rotationAngle: .pi * 225 / 180)
    }

    private let failedContainer = UIView().then {
        $0.backgroundColor = .clear
        $0.isHidden = true
    }

    private let retryButton = UIButton().then {
        $0.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        $0.tintColor = ColorSystem.gray60
    }

    private let deleteButton = UIButton().then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .systemRed
    }

    private let imageContainerView = UIView().then {
        $0.backgroundColor = .clear
        $0.isHidden = true
    }

    var onRetryTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?

    private var cachedTextSize: CGSize?
    private var cachedMaxWidth: CGFloat?
    private var cachedContent: String?
    private var cachedFiles: [String]?

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
        bubbleView.addSubview(imageContainerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(sendingIndicator)
        containerView.addSubview(failedContainer)

        failedContainer.addSubview(retryButton)
        failedContainer.addSubview(deleteButton)

        retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)
    }

    @objc private func handleRetryTap() {
        onRetryTapped?()
    }

    @objc private func handleDeleteTap() {
        onDeleteTapped?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxBubbleWidth = contentView.bounds.width * 0.65
        let padding: CGFloat = 12

        containerView.pin.all()

        let hasImages = !imageContainerView.isHidden && !(cachedFiles?.isEmpty ?? true)
        let hasText = !(cachedContent?.isEmpty ?? true)

        if cachedTextSize == nil || cachedMaxWidth != maxBubbleWidth {
            let maxTextWidth = maxBubbleWidth - padding * 2
            let textSize = messageLabel.sizeThatFits(
                CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextSize = textSize
            cachedMaxWidth = maxBubbleWidth
        }

        let textSize = cachedTextSize!
        var bubbleWidth = hasText ? textSize.width + padding * 2 : padding * 2
        var contentHeight: CGFloat = 0

        if hasText {
            messageLabel.pin
                .top(padding)
                .left(padding)
                .width(textSize.width)
                .height(textSize.height)
            contentHeight = textSize.height
        }

        if hasImages {
            let imageSize: CGFloat = 80
            let imageCount = cachedFiles?.count ?? 0
            let rowCount = (imageCount + 1) / 2
            let colCount = min(imageCount, 2)

            let totalImageWidth = CGFloat(colCount) * imageSize + CGFloat(colCount - 1) * 4
            let totalImageHeight = CGFloat(rowCount) * imageSize + CGFloat(max(0, rowCount - 1)) * 4

            bubbleWidth = max(bubbleWidth, totalImageWidth + padding * 2)

            if hasText {
                imageContainerView.pin
                    .below(of: messageLabel)
                    .marginTop(8)
                    .left(padding)
                    .width(totalImageWidth)
                    .height(totalImageHeight)
                contentHeight += 8 + totalImageHeight
            } else {
                imageContainerView.pin
                    .top(padding)
                    .left(padding)
                    .width(totalImageWidth)
                    .height(totalImageHeight)
                contentHeight = totalImageHeight
            }

            imageContainerView.flex.layout()
        }

        let bubbleHeight = contentHeight + padding * 2

        bubbleView.pin
            .top(8)
            .right(16)
            .width(bubbleWidth)
            .height(bubbleHeight)

        timeLabel.pin
            .before(of: bubbleView, aligned: .bottom)
            .marginRight(8)
            .sizeToFit()

        sendingIndicator.pin
            .before(of: timeLabel, aligned: .center)
            .marginRight(4)
            .size(16)

        let buttonSize: CGFloat = 20
        let buttonSpacing: CGFloat = 4
        let containerWidth = buttonSize * 2 + buttonSpacing

        failedContainer.pin
            .before(of: timeLabel, aligned: .center)
            .marginRight(4)
            .width(containerWidth)
            .height(buttonSize)

        retryButton.pin
            .left()
            .vCenter()
            .size(buttonSize)

        deleteButton.pin
            .right()
            .vCenter()
            .size(buttonSize)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxBubbleWidth = size.width * 0.65
        let padding: CGFloat = 12

        let hasImages = !imageContainerView.isHidden && !(cachedFiles?.isEmpty ?? true)
        let hasText = !(cachedContent?.isEmpty ?? true)

        if cachedTextSize == nil || cachedMaxWidth != maxBubbleWidth {
            let maxTextWidth = maxBubbleWidth - padding * 2
            let textSize = messageLabel.sizeThatFits(
                CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextSize = textSize
            cachedMaxWidth = maxBubbleWidth
        }

        var contentHeight: CGFloat = 0

        if hasText {
            contentHeight = cachedTextSize!.height
        }

        if hasImages {
            let imageSize: CGFloat = 80
            let imageCount = cachedFiles?.count ?? 0
            let rowCount = (imageCount + 1) / 2
            let totalImageHeight = CGFloat(rowCount) * imageSize + CGFloat(max(0, rowCount - 1)) * 4

            if hasText {
                contentHeight += 8 + totalImageHeight
            } else {
                contentHeight = totalImageHeight
            }
        }

        let bubbleHeight = contentHeight + padding * 2
        return CGSize(width: size.width, height: bubbleHeight + 16)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cachedTextSize = nil
        cachedMaxWidth = nil
        cachedContent = nil
        cachedFiles = nil
        sendingIndicator.isHidden = true
        failedContainer.isHidden = true
        imageContainerView.isHidden = true
        imageContainerView.subviews.forEach { $0.removeFromSuperview() }
        onRetryTapped = nil
        onDeleteTapped = nil
    }

    func configure(with message: ChatMessage) {
        if cachedContent != message.content || cachedFiles != message.files {
            cachedTextSize = nil
            cachedContent = message.content
            cachedFiles = message.files
        }

        messageLabel.typography(FontSystem.Pretendard.body2, text: message.content)
        timeLabel.typography(FontSystem.Pretendard.caption2, text: formatTime(message.createdAt))

        imageContainerView.subviews.forEach { $0.removeFromSuperview() }

        if let files = message.files, !files.isEmpty {
            imageContainerView.isHidden = false

            let imageSize: CGFloat = 80

            var imageViews: [UIImageView] = []

            for filePath in files {
                let imageView = UIImageView().then {
                    $0.contentMode = .scaleAspectFill
                    $0.clipsToBounds = true
                    $0.layer.cornerRadius = 8
                    $0.backgroundColor = ColorSystem.gray30
                }

                let baseURL = NetworkConfig.baseURL
                let fullURLString = baseURL + filePath

                imageView.setImage(from: fullURLString)
                imageViews.append(imageView)
            }

            imageContainerView.flex
                .direction(.column)
                .define { flex in
                    var currentRow: Flex?

                    for (index, imageView) in imageViews.enumerated() {
                        if index % 2 == 0 {
                            currentRow = flex.addItem()
                                .direction(.row)

                            if index > 0 {
                                currentRow?.marginTop(4)
                            }
                        }

                        if index % 2 == 0 {
                            currentRow?.addItem(imageView).width(imageSize).height(imageSize)
                        } else {
                            currentRow?.addItem(imageView).width(imageSize).height(imageSize).marginLeft(4)
                        }
                    }
                }
        } else {
            imageContainerView.isHidden = true
        }

        switch message.sendStatus {
        case .sent:
            sendingIndicator.isHidden = true
            failedContainer.isHidden = true

        case .sending:
            sendingIndicator.isHidden = false
            failedContainer.isHidden = true

        case .failed:
            sendingIndicator.isHidden = true
            failedContainer.isHidden = false
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
