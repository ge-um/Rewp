//
//  VideoPlayerService.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import AVFoundation
import RxSwift
import RxCocoa

final class VideoPlayerService {
    private let player = AVPlayer()
    private var currentItem: AVPlayerItem?
    private var timeObserver: Any?
    private let disposeBag = DisposeBag()
    private var pendingSeekTime: CMTime?
    private var shouldAutoPlay = false

    var playerLayer: AVPlayerLayer {
        return AVPlayerLayer(player: player)
    }

    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    let currentTime = BehaviorRelay<TimeInterval>(value: 0)
    let duration = BehaviorRelay<TimeInterval>(value: 0)

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

    init() {
        setupTimeObserver()
        setupNotifications()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }

    func loadVideo(url: String) {
        guard let videoUrl = URL(string: url) else {
            playbackState.accept(.failed(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        playbackState.accept(.loading)

        let newItem = AVPlayerItem(url: videoUrl)
        currentItem = newItem
        player.replaceCurrentItem(with: newItem)

        observePlayerItemStatus(item: newItem)
            .withUnretained(self)
            .subscribe(onNext: { owner, status in
                switch status {
                case .readyToPlay:
                    if let seekTime = owner.pendingSeekTime {
                        owner.player.seek(to: seekTime)
                        owner.pendingSeekTime = nil
                    }

                    if owner.shouldAutoPlay {
                        owner.play()
                        owner.shouldAutoPlay = false
                    } else {
                        owner.playbackState.accept(.paused)
                    }
                case .failed:
                    let error = newItem.error ?? NSError(domain: "Unknown error", code: -1)
                    owner.playbackState.accept(.failed(error))
                default:
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

    func switchQuality(url: String) {
        let currentTime = player.currentTime()
        let wasPlaying = playbackState.value.isPlaying

        pendingSeekTime = currentTime
        shouldAutoPlay = wasPlaying

        loadVideo(url: url)
    }

    func reset() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        playbackState.accept(.idle)
        currentTime.accept(0)
        duration.accept(0)
    }

    private func setupTimeObserver() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime.accept(time.seconds)
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
            let observation = item.observe(\.status, options: [.new]) { item, _ in
                observer.onNext(item.status)
            }
            return Disposables.create {
                observation.invalidate()
            }
        }
    }

    private func observeDuration(item: AVPlayerItem) -> Observable<CMTime> {
        return Observable.create { observer in
            let observation = item.observe(\.duration, options: [.new]) { item, _ in
                observer.onNext(item.duration)
            }
            return Disposables.create {
                observation.invalidate()
            }
        }
    }
}
