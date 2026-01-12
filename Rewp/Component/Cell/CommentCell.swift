//
//  CommentCell.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import UIKit
import PinLayout
import Then
import Kingfisher

final class CommentCell: UITableViewCell, IsIdentifiable {

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

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(contentLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        profileImageView.pin
            .top(16)
            .left(20)
            .size(32)

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
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.pin.width(size.width)
        layoutSubviews()

        let height = contentLabel.frame.maxY + 16
        return CGSize(width: size.width, height: height)
    }

    func configure(with comment: Comment) {
        nicknameLabel.text = comment.creatorNickname
        timeLabel.text = comment.relativeTime
        contentLabel.typography(FontSystem.Pretendard.body2, text: comment.content)

        if let profileImageURL = comment.creatorProfileImage, let url = URL(string: profileImageURL) {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = nil
        }
        setNeedsLayout()
    }
}
