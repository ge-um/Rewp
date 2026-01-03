//
//  ChatMessageReceivedCell.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import PinLayout
import Then
import Kingfisher

final class ChatMessageReceivedCell: UITableViewCell, IsIdentifiable {
    static let identifier = "ChatMessageReceivedCell"

    private let containerView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
    }

    private let nicknameLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    private let bubbleView = UIView().then {
        $0.backgroundColor = ColorSystem.gray45
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

    private let messageLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 0
    }

    private let timeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
    }

    private var cachedTextSize: CGSize?
    private var cachedNicknameSize: CGSize?
    private var cachedMaxWidth: CGFloat?
    private var cachedContent: String?
    private var cachedNickname: String?

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
        containerView.addSubview(profileImageView)
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxBubbleWidth = contentView.bounds.width * 0.65
        let padding: CGFloat = 12

        containerView.pin.all()

        profileImageView.pin
            .top(8)
            .left(16)
            .size(40)

        if cachedNicknameSize == nil {
            nicknameLabel.pin.sizeToFit()
            cachedNicknameSize = nicknameLabel.frame.size
        }

        nicknameLabel.pin
            .after(of: profileImageView)
            .marginLeft(8)
            .top(8)
            .width(cachedNicknameSize!.width)
            .height(cachedNicknameSize!.height)

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
            .below(of: nicknameLabel)
            .marginTop(4)
            .after(of: profileImageView)
            .marginLeft(8)
            .width(bubbleWidth)
            .height(bubbleHeight)

        messageLabel.pin
            .top(padding)
            .left(padding)
            .width(textSize.width)
            .height(textSize.height)

        timeLabel.pin
            .after(of: bubbleView, aligned: .bottom)
            .marginLeft(8)
            .sizeToFit()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxBubbleWidth = size.width * 0.65
        let padding: CGFloat = 12

        if cachedNicknameSize == nil {
            nicknameLabel.pin.sizeToFit()
            cachedNicknameSize = nicknameLabel.frame.size
        }

        if cachedTextSize == nil || cachedMaxWidth != maxBubbleWidth {
            let maxTextWidth = maxBubbleWidth - padding * 2
            let textSize = messageLabel.sizeThatFits(
                CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)
            )
            cachedTextSize = textSize
            cachedMaxWidth = maxBubbleWidth
        }

        let bubbleHeight = cachedTextSize!.height + padding * 2
        let totalHeight = 8 + cachedNicknameSize!.height + 4 + bubbleHeight + 8
        return CGSize(width: size.width, height: totalHeight)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cachedTextSize = nil
        cachedNicknameSize = nil
        cachedMaxWidth = nil
        cachedContent = nil
        cachedNickname = nil
    }

    func configure(with message: ChatMessage) {
        if cachedContent != message.content {
            cachedTextSize = nil
            cachedContent = message.content
        }

        if cachedNickname != message.senderNickname {
            cachedNicknameSize = nil
            cachedNickname = message.senderNickname
        }

        nicknameLabel.typography(FontSystem.Pretendard.caption1Semibold, text: message.senderNickname)
        messageLabel.typography(FontSystem.Pretendard.body2, text: message.content)
        timeLabel.typography(FontSystem.Pretendard.caption2, text: formatTime(message.createdAt))

        if let profileImageURL = message.senderProfileImage,
           let url = URL(string: NetworkConfig.baseURL.replacingOccurrences(of: "/v1", with: "") + "/" + profileImageURL) {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = nil
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
