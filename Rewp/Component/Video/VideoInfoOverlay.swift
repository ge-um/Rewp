//
//  VideoInfoOverlay.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import FlexLayout
import PinLayout
import Then

final class VideoInfoOverlay: UIView {
    private let containerView = UIView()

    private let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.numberOfLines = 2
    }

    private let descriptionLabel = UILabel().then {
        $0.textColor = UIColor.white.withAlphaComponent(0.8)
        $0.numberOfLines = 3
    }

    private let viewCountLabel = UILabel().then {
        $0.textColor = UIColor.white.withAlphaComponent(0.7)
    }

    var onLikeTapped: (() -> Void)?

    private let likeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        $0.tintColor = .white
    }

    private let likeCountLabel = UILabel().then {
        $0.textColor = .white
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)

        containerView.flex
            .direction(.row)
            .paddingTop(20)
            .paddingLeft(20)
            .paddingRight(20)
            .paddingBottom(40)
            .alignItems(.start)
            .define { flex in
                flex.addItem()
                    .direction(.column)
                    .grow(1)
                    .shrink(1)
                    .define { flex in
                        flex.addItem(titleLabel).marginBottom(8)
                        flex.addItem(descriptionLabel).marginBottom(12)
                        flex.addItem(viewCountLabel)
                    }

                flex.addItem()
                    .direction(.column)
                    .alignItems(.center)
                    .width(60)
                    .shrink(0)
                    .define { flex in
                        flex.addItem(likeButton)
                            .width(44)
                            .height(44)
                        flex.addItem(likeCountLabel)
                            .marginTop(4)
                            .width(100%)
                    }
            }

        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    func configure(video: Video) {
        titleLabel.typography(FontSystem.Pretendard.title1Bold, text: video.title)
        descriptionLabel.typography(FontSystem.Pretendard.body2, text: video.description)
        viewCountLabel.typography(FontSystem.Pretendard.body3, text: "조회수 \(video.formattedViewCount)")

        updateLike(count: video.likeCount, isLiked: video.isLiked)
    }

    func updateLike(count: Int, isLiked: Bool) {
        likeButton.isSelected = isLiked
        likeCountLabel.typography(FontSystem.Pretendard.body3, text: "\(count)")
    }

    @objc private func likeTapped() {
        onLikeTapped?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.pin.all()
        containerView.flex.layout()
    }
}
