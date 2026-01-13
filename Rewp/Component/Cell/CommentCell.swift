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
import RxSwift
import RxCocoa

final class CommentCell: UITableViewCell, IsIdentifiable {

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
        $0.baselineAdjustment = .alignCenters
    }

    private let timeLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.caption2.font
        $0.textColor = ColorSystem.gray45
        $0.baselineAdjustment = .alignCenters

    }

    private let contentLabel = UILabel().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 0
    }

    private let replyButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero

        var titleAttr = AttributedString("답글")
        titleAttr.font = FontSystem.Pretendard.caption1Regular.font
        titleAttr.foregroundColor = ColorSystem.gray60
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray60

        $0.configuration = config
    }

    private let editButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero

        var titleAttr = AttributedString("수정")
        titleAttr.font = FontSystem.Pretendard.caption1Regular.font
        titleAttr.foregroundColor = ColorSystem.gray60
        config.attributedTitle = titleAttr

        config.baseForegroundColor = ColorSystem.gray60

        $0.configuration = config
        $0.isHidden = true
    }

    var replyTapped: Observable<Void> {
        return replyButton.rx.tap.asObservable()
    }

    var editTapped: Observable<Void> {
        return editButton.rx.tap.asObservable()
    }

    var disposeBag = DisposeBag()

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
        disposeBag = DisposeBag()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(childConnectionLine)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(replyButton)
        contentView.addSubview(editButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        profileImageView.pin
            .top(8)
            .left(20)
            .size(32)

        nicknameLabel.pin
            .after(of: profileImageView)
            .marginLeft(12)
            .top(12)
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

        replyButton.pin
            .below(of: contentLabel)
            .marginTop(8)
            .left(to: nicknameLabel.edge.left)
            .sizeToFit()

        editButton.pin
            .after(of: replyButton)
            .marginLeft(12)
            .vCenter(to: replyButton.edge.vCenter)
            .sizeToFit()

        let profileCenterX = profileImageView.frame.minX + 16
        childConnectionLine.pin
            .top(profileImageView.frame.maxY)
            .left(profileCenterX - 0.5)
            .width(1)
            .bottom()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.pin.width(size.width)
        layoutSubviews()

        let height: CGFloat
        if editButton.isHidden {
            height = replyButton.frame.maxY
        } else {
            height = max(replyButton.frame.maxY, editButton.frame.maxY)
        }
        return CGSize(width: size.width, height: height)
    }

    func configure(with comment: Comment, hasReplies: Bool, isCurrentUser: Bool) {
        nicknameLabel.text = comment.creatorNickname
        timeLabel.text = comment.relativeTime
        contentLabel.typography(FontSystem.Pretendard.body2, text: comment.content)

        profileImageView.setImage(from: comment.creatorProfileImage, targetSize: CGSize(width: 32, height: 32))

        childConnectionLine.isHidden = !hasReplies
        editButton.isHidden = !isCurrentUser
    }
}
