//
//  PostCell.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import UIKit
import PinLayout
import FlexLayout
import Then
import Kingfisher

final class PostCell: UITableViewCell, IsIdentifiable {

    private let cardView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.borderColor = ColorSystem.gray15.cgColor
    }

    private let profileContainer = UIView()

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }

    private let profileInfoContainer = UIView()

    private let nicknameLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption1Medium.font
        $0.textColor = ColorSystem.gray90
    }

    private let timeLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption2.font
        $0.textColor = ColorSystem.gray45
    }

    private let titleLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body1Bold.font
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let contentLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body3.font
        $0.textColor = ColorSystem.gray60
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private let interactionContainer = UIView()

    private let likeIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray45
        $0.contentMode = .scaleAspectFit
    }

    private let likeCountLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption2.font
        $0.textColor = ColorSystem.gray45
    }

    private let commentIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "bubble.right")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = ColorSystem.gray45
        $0.contentMode = .scaleAspectFit
    }

    private let commentCountLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption2.font
        $0.textColor = ColorSystem.gray45
    }
    
    private let divider = ItemDivider()

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
        thumbnailImageView.kf.cancelDownloadTask()
        profileImageView.image = nil
        thumbnailImageView.image = nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        
        cardView.addSubview(divider)
        
        cardView.addSubview(profileContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(contentLabel)
        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(interactionContainer)

        profileContainer.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                flex.addItem(profileImageView).size(32)
                flex.addItem(profileInfoContainer).marginLeft(8).grow(1)
            }

        profileInfoContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem(nicknameLabel)
                flex.addItem(timeLabel).marginTop(2)
            }

        interactionContainer.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                flex.addItem(likeIconImageView)
                    .size(16)
                flex.addItem(likeCountLabel)
                    .marginLeft(4)
                flex.addItem(commentIconImageView)
                    .size(16)
                    .marginLeft(8)
                flex.addItem(commentCountLabel)
                    .marginLeft(4)
            }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        cardView.pin
            .horizontally()
            .height(136)
        
        divider.pin
            .bottom()
            .horizontally()

        profileContainer.pin
            .top(16)
            .left(20)
            .right(20)
            .height(32)

        profileContainer.flex.layout()

        if !thumbnailImageView.isHidden {
            thumbnailImageView.pin
                .right(20)
                .vCenter()
                .size(88)

            titleLabel.pin
                .below(of: profileContainer)
                .marginTop(8)
                .left(20)
                .right(to: thumbnailImageView.edge.left)
                .marginRight(12)
                .height(20)

            contentLabel.pin
                .below(of: titleLabel)
                .marginTop(4)
                .left(20)
                .right(to: thumbnailImageView.edge.left)
                .marginRight(12)
                .height(20)
        } else {
            titleLabel.pin
                .below(of: profileContainer)
                .marginTop(8)
                .left(20)
                .right(20)
                .height(20)

            contentLabel.pin
                .below(of: titleLabel)
                .marginTop(4)
                .left(20)
                .right(20)
                .height(20)
        }

        interactionContainer.pin
            .left(20)
            .below(of: contentLabel)
            .marginTop(4)
            .height(20)

        interactionContainer.flex.layout(mode: .adjustWidth)
        
        divider.pin
            .bottom()
            .horizontally()
    }
    
    func configure(with post: Post) {
        nicknameLabel.text = post.creatorNickname
        timeLabel.text = post.relativeTime
        titleLabel.text = post.title
        contentLabel.text = post.content
        likeCountLabel.text = "\(post.likesCount)"
        commentCountLabel.text = "\(post.commentsCount)"

        profileImageView.setImage(from: post.creatorProfileImage)

        if let thumbnailURL = post.thumbnailURL {
            thumbnailImageView.isHidden = false
            thumbnailImageView.setImage(from: thumbnailURL)
        } else {
            thumbnailImageView.isHidden = true
            thumbnailImageView.image = nil
        }
    }
}
