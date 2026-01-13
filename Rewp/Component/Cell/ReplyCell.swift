//
//  ReplyCell.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import PinLayout
import Then
import Kingfisher

final class ReplyCell: UITableViewCell, IsIdentifiable {

    private let verticalConnectionLine = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }

    private let horizontalConnectionLine = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }

    private let childConnectionLine = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }

    private let nicknameLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption1Medium.font
        $0.textColor = ColorSystem.gray90
    }

    private let timeLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption2.font
        $0.textColor = ColorSystem.gray45
    }

    private let contentLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.kf.cancelDownloadTask()
        profileImageView.image = nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(verticalConnectionLine)
        contentView.addSubview(horizontalConnectionLine)
        contentView.addSubview(childConnectionLine)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(contentLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let parentProfileCenterX: CGFloat = 20 + 16
        let replyProfileLeft: CGFloat = 64

        profileImageView.pin
            .top(16)
            .left(replyProfileLeft)
            .size(32)

        let replyProfileCenterY = profileImageView.frame.minY + 16

        horizontalConnectionLine.pin
            .vCenter(to: profileImageView.edge.vCenter)
            .left(parentProfileCenterX)
            .width(replyProfileLeft - parentProfileCenterX)
            .height(1)

        nicknameLabel.pin
            .after(of: profileImageView)
            .marginLeft(12)
            .top(16)
            .sizeToFit()

        timeLabel.pin
            .after(of: nicknameLabel)
            .marginLeft(8)
            .vCenter(to: nicknameLabel.edge.vCenter)
            .sizeToFit()

        contentLabel.pin
            .below(of: nicknameLabel)
            .marginTop(8)
            .left(to: nicknameLabel.edge.left)
            .right(20)
            .sizeToFit(.width)

        if childConnectionLine.isHidden {
            verticalConnectionLine.pin
                .top()
                .left(parentProfileCenterX - 0.5)
                .width(1)
                .height(replyProfileCenterY)
        } else {
            verticalConnectionLine.pin
                .top()
                .left(parentProfileCenterX - 0.5)
                .width(1)
                .bottom()
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.pin.width(size.width)
        layoutSubviews()

        let height = contentLabel.frame.maxY + 16
        return CGSize(width: size.width, height: height)
    }

    func configure(with reply: Reply, hasReplies: Bool) {
        nicknameLabel.text = reply.creatorNickname
        timeLabel.text = reply.relativeTime
        contentLabel.typography(FontSystem.Pretendard.body2, text: reply.content)

        profileImageView.setImage(from: reply.creatorProfileImage, targetSize: CGSize(width: 32, height: 32))

        childConnectionLine.isHidden = !hasReplies
    }
}
