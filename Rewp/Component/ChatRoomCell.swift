//
//  ChatRoomCell.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import PinLayout
import Then
import Kingfisher

final class ChatRoomCell: UITableViewCell, IsIdentifiable {

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 28
        $0.clipsToBounds = true
    }

    private let contentContainer = UIView()

    private let nicknameLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let lastMessageLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.numberOfLines = 1
    }

    private let timeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray45
    }

    private let unreadBadge = UILabel().then {
        $0.textColor = ColorSystem.gray0
        $0.backgroundColor = ColorSystem.brightCoast
        $0.textAlignment = .center
        $0.clipsToBounds = true
        $0.isHidden = true
        $0.layer.cornerRadius = 10
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
        contentView.addSubview(contentContainer)
        contentContainer.addSubview(nicknameLabel)
        contentContainer.addSubview(lastMessageLabel)
        contentContainer.addSubview(timeLabel)
        contentContainer.addSubview(unreadBadge)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        profileImageView.pin
            .left(20)
            .vCenter()
            .size(56)

        contentContainer.pin
            .after(of: profileImageView)
            .marginLeft(12)
            .vCenter(to: profileImageView.edge.vCenter)
            .right(20)
            .height(44)

        nicknameLabel.pin
            .top()
            .left()
            .sizeToFit()

        timeLabel.pin
            .right()
            .vCenter(to: nicknameLabel.edge.vCenter)
            .sizeToFit()

        lastMessageLabel.pin
            .bottom()
            .left()
            .sizeToFit()

        unreadBadge.pin
            .right()
            .vCenter(to: lastMessageLabel.edge.vCenter)
            .size(20)
    }

    func configure(with chatRoom: ChatRoom) {
        nicknameLabel.typography(FontSystem.Pretendard.body1, text: chatRoom.participantName)
        lastMessageLabel.typography(FontSystem.Pretendard.body3, text: chatRoom.lastMessage)
        timeLabel.typography(FontSystem.Pretendard.caption2, text: chatRoom.relativeTime)

        if chatRoom.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadBadge.typography(FontSystem.Pretendard.caption2, text: "\(chatRoom.unreadCount)")
        } else {
            unreadBadge.isHidden = true
        }

        if let profileImageURL = chatRoom.participantProfileImage,
           let url = URL(string: profileImageURL) {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = nil
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 80)
    }
}
