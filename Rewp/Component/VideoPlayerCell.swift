//
//  VideoPlayerCell.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import PinLayout
import RxSwift
import OSLog

final class VideoPlayerCell: UICollectionViewCell, IsIdentifiable {
    private let playerView = VideoPlayerView()
    private let infoOverlay = VideoInfoOverlay()
    private let subtitleView = SubtitleView()
    private let playerService = VideoPlayerService()

    var onLikeTapped: (() -> Void)?
    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupPlayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playerService.pause()
        playerService.reset()
    }

    private func setupUI() {
        contentView.addSubview(playerView)
        contentView.addSubview(subtitleView)
        contentView.addSubview(infoOverlay)
    }

    private func setupPlayer() {
        playerView.configure(with: playerService)

        playerService.currentSubtitle
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.subtitleView.setText(text)
            })
            .disposed(by: disposeBag)
    }

    func configure(video: Video) {
        Logger.video.debug("Configuring cell for video: \(video.videoId)")
        infoOverlay.configure(video: video)

        infoOverlay.onLikeTapped = { [weak self] in
            self?.onLikeTapped?()
        }
    }

    func loadVideo(url: String, subtitleUrl: String?) {
        Logger.video.notice("Loading video: \(url, privacy: .public)")
        playerService.loadVideo(url: url, subtitleUrl: subtitleUrl, autoPlay: false)
    }

    func play() {
        playerService.play()
    }

    func pause() {
        playerService.pause()
    }

    func updateLike(count: Int, isLiked: Bool) {
        infoOverlay.updateLike(count: count, isLiked: isLiked)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        playerView.pin.all()

        subtitleView.pin
            .horizontally(40)
            .bottom(100)
            .height(100)

        infoOverlay.pin
            .bottom(0)
            .horizontally()
            .height(200)
    }
}
