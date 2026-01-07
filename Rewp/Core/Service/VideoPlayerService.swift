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
    private var pendingSeekTime: CMTime?
    private var currentSubtitleTrack: SubtitleTrack?
    private let subtitleService: SubtitleService

    private(set) lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    let currentTime = BehaviorRelay<TimeInterval>(value: 0)
    let duration = BehaviorRelay<TimeInterval>(value: 0)
    let currentSubtitle = BehaviorRelay<String?>(value: nil)

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

    init(subtitleService: SubtitleService = SubtitleService()) {
        self.subtitleService = subtitleService
        setupTimeObserver()
        setupNotifications()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }

    func loadVideo(url: String, subtitleUrl: String? = nil, autoPlay: Bool = false) {
        Logger.video.notice("Loading video - autoPlay: \(autoPlay), hasSubtitle: \(subtitleUrl != nil)")
        playbackState.accept(.loading)

        if let subtitleUrl = subtitleUrl {
            subtitleService.downloadSubtitle(url: subtitleUrl)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onSuccess: { [weak self] track in
                        Logger.video.debug("Subtitle downloaded - \(track.subtitles.count) entries")
                        self?.currentSubtitleTrack = track
                        self?.createPlayerItem(videoUrl: url, autoPlay: autoPlay)
                    },
                    onFailure: { [weak self] error in
                        Logger.video.error("Subtitle download failed - \(error.localizedDescription)")
                        self?.createPlayerItem(videoUrl: url, autoPlay: autoPlay)
                    }
                )
                .disposed(by: disposeBag)
        } else {
            currentSubtitleTrack = nil
            createPlayerItem(videoUrl: url, autoPlay: autoPlay)
        }
    }

    private func createPlayerItem(videoUrl: String, autoPlay: Bool) {
        guard let url = URL(string: videoUrl) else {
            playbackState.accept(.failed(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        let newItem = AVPlayerItem(url: url)
        currentItem = newItem
        player.replaceCurrentItem(with: newItem)

        observePlayerItemStatus(item: newItem)
            .withUnretained(self)
            .subscribe(onNext: { owner, status in
                switch status {
                case .unknown:
                    Logger.video.debug("Player item status: unknown")
                case .readyToPlay:
                    Logger.video.notice("Player item ready to play - autoPlay: \(autoPlay)")

                    if let seekTime = owner.pendingSeekTime {
                        owner.player.seek(to: seekTime)
                        owner.pendingSeekTime = nil
                        Logger.video.debug("Seeked to pending time")
                    }

                    if autoPlay {
                        owner.play()
                        Logger.video.notice("Auto-play started")
                    } else {
                        owner.playbackState.accept(.paused)
                        Logger.video.debug("Ready but not auto-playing")
                    }
                case .failed:
                    let error = newItem.error ?? NSError(domain: "Unknown error", code: -1)
                    Logger.video.error("Player item failed - \(error.localizedDescription)")
                    owner.playbackState.accept(.failed(error))
                @unknown default:
                    Logger.video.debug("Player item status: unknown default")
                    break
                }
            })
            .disposed(by: disposeBag)

        observeDuration(item: newItem)
            .withUnretained(self)
            .subscribe(onNext: { owner, cmTime in
                let durationSeconds = cmTime.seconds
                if !durationSeconds.isNaN && !durationSeconds.isInfinite {
                    owner.duration.accept(durationSeconds)
                }
            })
            .disposed(by: disposeBag)
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

    func switchQuality(url: String, subtitleUrl: String? = nil) {
        let currentTime = player.currentTime()
        let wasPlaying = playbackState.value.isPlaying

        Logger.video.notice("Switching quality - wasPlaying: \(wasPlaying), currentTime: \(currentTime.seconds)")
        pendingSeekTime = currentTime

        loadVideo(url: url, subtitleUrl: subtitleUrl, autoPlay: wasPlaying)
    }

    func reset() {
        player.pause()
        player.replaceCurrentItem(with: nil)
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
