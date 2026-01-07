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
    static var subtitleService: SubtitleService!

    private let playerView = VideoPlayerView()
    private let infoOverlay = VideoInfoOverlay()
    private let subtitleView = SubtitleView()
    private let subtitleButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "captions.bubble")
        config.baseForegroundColor = .white
        $0.configuration = config
    }
    private lazy var playerService: VideoPlayerService = {
        VideoPlayerService(subtitleService: Self.subtitleService)
    }()

    var onLikeTapped: (() -> Void)?
    private var disposeBag = DisposeBag()
    private var bottomSheet: SubtitleSelectionBottomSheet?

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
        contentView.addSubview(subtitleButton)
    }

    private func setupPlayer() {
        playerView.configure(with: playerService)

        playerService.currentSubtitle
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.subtitleView.setText(text)
            })
            .disposed(by: disposeBag)

        subtitleButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.showSubtitleSelection()
            })
            .disposed(by: disposeBag)
    }

    private func showSubtitleSelection() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let sheet = SubtitleSelectionBottomSheet()
        bottomSheet = sheet

        sheet.configure(
            subtitles: playerService.getAvailableSubtitles(),
            selectedLanguage: playerService.selectedSubtitleLanguage.value
        )

        sheet.onSubtitleSelected = { [weak self] subtitleInfo in
            self?.playerService.switchSubtitle(to: subtitleInfo)
        }

        sheet.show(in: window)
    }

    func configure(video: Video) {
        Logger.video.debug("Configuring cell for video: \(video.videoId)")
        infoOverlay.configure(video: video)

        infoOverlay.onLikeTapped = { [weak self] in
            self?.onLikeTapped?()
        }
    }

    func loadVideo(url: String, subtitles: [SubtitleInfo]) {
        Logger.video.notice("Loading video: \(url, privacy: .public)")
        playerService.loadVideo(url: url, subtitles: subtitles, autoPlay: false)
        subtitleButton.isHidden = subtitles.isEmpty
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

        subtitleButton.pin
            .top(contentView.pin.safeArea.top + 16)
            .right(16)
            .size(44)

        subtitleView.pin
            .horizontally(40)
            .bottom(180)
            .height(100)

        infoOverlay.pin
            .bottom(0)
            .horizontally()
            .height(200)
    }
}
