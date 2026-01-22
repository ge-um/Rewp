//
//  VideoPlayerService.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import AVFoundation
import RxSwift
import RxCocoa
import OSLog

final class VideoPlayerService {
    private let player = AVPlayer()
    private var currentItem: AVPlayerItem?
    private var timeObserver: Any?
    private let disposeBag = DisposeBag()
    private var itemDisposeBag = DisposeBag()
    private var pendingSeekTime: CMTime?
    private var pendingAutoPlay: Bool = false
    private var currentSubtitleTrack: SubtitleTrack?
    private let subtitleService: SubtitleService
    private var availableSubtitles: [SubtitleInfo] = []
    private var selectedSubtitleInfo: SubtitleInfo?

    private(set) lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    let currentTime = BehaviorRelay<TimeInterval>(value: 0)
    let duration = BehaviorRelay<TimeInterval>(value: 0)
    let currentSubtitle = BehaviorRelay<String?>(value: nil)
    let selectedSubtitleLanguage = BehaviorRelay<String?>(value: nil)

    enum PlaybackState {
        case idle
        case loading
        case playing
        case paused
        case ended
        case failed(Error)

        var isPlaying: Bool {
            if case .playing = self {
                return true
            }
            return false
        }
    }

    init(subtitleService: SubtitleService) {
        self.subtitleService = subtitleService
        player.appliesMediaSelectionCriteriaAutomatically = false
        setupTimeObserver()
        setupNotifications()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }

    func loadVideo(url: String, subtitles: [SubtitleInfo]) {
        player.pause()
        itemDisposeBag = DisposeBag()

        self.availableSubtitles = subtitles
        Logger.video.notice("Loading video - availableSubtitles: \(subtitles.count)")
        playbackState.accept(.loading)

        createPlayerItem(videoUrl: url)

        let defaultSubtitle = subtitles.first(where: { $0.isDefault }) ?? subtitles.first
        selectedSubtitleInfo = defaultSubtitle

        if let subtitle = defaultSubtitle {
            selectedSubtitleLanguage.accept(subtitle.language)
            Logger.video.notice("Default subtitle selected - \(subtitle.displayName)")

            subtitleService.downloadSubtitle(url: subtitle.url)
                .observe(on: MainScheduler.instance)
                .asObservable()
                .withUnretained(self)
                .subscribe(
                    onNext: { owner, track in
                        Logger.video.debug("Subtitle downloaded - \(track.subtitles.count) entries")
                        owner.currentSubtitleTrack = track
                    },
                    onError: { error in
                        Logger.video.error("Subtitle download failed - \(error.localizedDescription)")
                    }
                )
                .disposed(by: itemDisposeBag)
        } else {
            selectedSubtitleLanguage.accept(nil)
            currentSubtitleTrack = nil
        }
    }

    private func createPlayerItem(videoUrl: String) {
        guard let url = URL(string: videoUrl) else {
            playbackState.accept(.failed(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let asset = AVURLAsset(url: url)
        let newItem = AVPlayerItem(asset: asset)

        currentItem = newItem
        player.replaceCurrentItem(with: newItem)
        bindPlayerItem(newItem)
    }

    private func bindPlayerItem(_ newItem: AVPlayerItem) {
        observePlayerItemStatus(item: newItem)
            .withUnretained(self)
            .subscribe(onNext: { owner, status in
                switch status {
                case .unknown:
                    Logger.video.debug("Player item status: unknown")
                case .readyToPlay:
                    Logger.video.notice("Player item ready to play")

                    if let seekTime = owner.pendingSeekTime {
                        owner.player.seek(to: seekTime)
                        owner.pendingSeekTime = nil
                        Logger.video.debug("Seeked to pending time")
                    }

                    if owner.pendingAutoPlay {
                        owner.play()
                        owner.pendingAutoPlay = false
                        Logger.video.debug("Resumed playback after quality switch")
                    } else {
                        owner.playbackState.accept(.paused)
                    }
                case .failed:
                    let error = newItem.error ?? NSError(domain: "Unknown error", code: -1)
                    let nsError = error as NSError
                    Logger.video.error("Player item failed - code: \(nsError.code), domain: \(nsError.domain), description: \(error.localizedDescription)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        Logger.video.error("Underlying error - code: \(underlyingError.code), domain: \(underlyingError.domain)")
                    }
                    owner.playbackState.accept(.failed(error))
                @unknown default:
                    Logger.video.debug("Player item status: unknown default")
                    break
                }
            })
            .disposed(by: itemDisposeBag)

        observeDuration(item: newItem)
            .withUnretained(self)
            .subscribe(onNext: { owner, cmTime in
                let durationSeconds = cmTime.seconds
                if !durationSeconds.isNaN && !durationSeconds.isInfinite {
                    owner.duration.accept(durationSeconds)
                }
            })
            .disposed(by: itemDisposeBag)
    }

    func play() {
        player.play()
        playbackState.accept(.playing)
    }

    func pause() {
        player.pause()
        playbackState.accept(.paused)
    }

    func seek(to time: TimeInterval) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func switchSubtitle(to subtitleInfo: SubtitleInfo?) {
        let currentTime = player.currentTime()
        let wasPlaying = playbackState.value.isPlaying

        if let subtitleInfo = subtitleInfo {
            selectedSubtitleInfo = subtitleInfo
            selectedSubtitleLanguage.accept(subtitleInfo.language)
            Logger.video.notice("Switching subtitle to \(subtitleInfo.displayName)")

            subtitleService.downloadSubtitle(url: subtitleInfo.url)
                .observe(on: MainScheduler.instance)
                .asObservable()
                .withUnretained(self)
                .subscribe(
                    onNext: { owner, track in
                        Logger.video.debug("Subtitle switched - \(track.subtitles.count) entries")
                        owner.currentSubtitleTrack = track
                        owner.player.seek(to: currentTime)
                        if wasPlaying {
                            owner.play()
                        }
                    },
                    onError: { error in
                        Logger.video.error("Subtitle switch failed - \(error.localizedDescription)")
                    }
                )
                .disposed(by: itemDisposeBag)
        } else {
            Logger.video.notice("Turning off subtitles")
            selectedSubtitleInfo = nil
            selectedSubtitleLanguage.accept(nil)
            currentSubtitleTrack = nil
            currentSubtitle.accept(nil)
        }
    }

    func getAvailableSubtitles() -> [SubtitleInfo] {
        return availableSubtitles
    }

    func switchQuality(url: String) {
        let currentTime = player.currentTime()
        let wasPlaying = playbackState.value.isPlaying

        Logger.video.notice("Switching quality - wasPlaying: \(wasPlaying), currentTime: \(currentTime.seconds)")
        pendingSeekTime = currentTime
        pendingAutoPlay = wasPlaying

        loadVideo(url: url, subtitles: availableSubtitles)
    }

    func reset() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        itemDisposeBag = DisposeBag()
        playbackState.accept(.idle)
        currentTime.accept(0)
        duration.accept(0)
        currentSubtitle.accept(nil)
    }


    private func setupTimeObserver() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            let currentTime = time.seconds
            self?.currentTime.accept(currentTime)

            if let subtitle = self?.currentSubtitleTrack?.subtitles.first(where: {
                currentTime >= $0.startTime && currentTime <= $0.endTime
            }) {
                self?.currentSubtitle.accept(subtitle.text)
            } else {
                self?.currentSubtitle.accept(nil)
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    @objc private func playerDidFinishPlaying() {
        playbackState.accept(.ended)
    }

    private func observePlayerItemStatus(item: AVPlayerItem) -> Observable<AVPlayerItem.Status> {
        return Observable.create { observer in
            let observation = item.observe(\.status, options: [.initial, .new]) { item, _ in
                observer.onNext(item.status)
            }
            return Disposables.create {
                observation.invalidate()
            }
        }
    }

    private func observeDuration(item: AVPlayerItem) -> Observable<CMTime> {
        return Observable.create { observer in
            let observation = item.observe(\.duration, options: [.initial, .new]) { item, _ in
                observer.onNext(item.duration)
            }
            return Disposables.create {
                observation.invalidate()
            }
        }
    }
}
