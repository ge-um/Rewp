//
//  VideoListPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class VideoListPresenter {
    private let repository: VideoRepository
    private let disposeBag = DisposeBag()

    init(repository: VideoRepository) {
        self.repository = repository
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let scrolledToVideo: Observable<Int>
        let likeButtonTapped: Observable<(index: Int, isLiked: Bool)>
        let qualitySelected: Observable<(index: Int, quality: VideoQuality)>
        let subtitleSelected: Observable<(index: Int, subtitle: SubtitleInfo?)>
    }

    struct Output {
        let videos: Driver<[Video]>
        let currentVideoIndex: Driver<Int>
        let streamInfo: Driver<(index: Int, streamInfo: VideoStreamInfo)>
        let likeUpdated: Driver<(index: Int, likeCount: Int, isLiked: Bool)>
        let error: Driver<String>
    }

    func transform(input: Input) -> Output {
        let videosRelay = BehaviorRelay<[Video]>(value: [])
        let currentIndexRelay = BehaviorRelay<Int>(value: 0)
        let streamInfoRelay = PublishRelay<(index: Int, streamInfo: VideoStreamInfo)>()
        let likeUpdateRelay = PublishRelay<(index: Int, likeCount: Int, isLiked: Bool)>()
        let errorRelay = PublishRelay<String>()

        var nextCursor: String?

        input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.repository.getVideos(next: nil, limit: 20)
                    .asObservable()
                    .catch { error in
                        Logger.network.error("Failed to fetch videos - \(error.localizedDescription)")
                        errorRelay.accept("비디오를 불러오는데 실패했습니다")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, result in
                videosRelay.accept(result.videos)
                nextCursor = result.nextCursor

                if let firstVideo = result.videos.first {
                    owner.loadStreamInfo(videoId: firstVideo.videoId, index: 0, relay: streamInfoRelay, errorRelay: errorRelay)
                }
            })
            .disposed(by: disposeBag)

        input.scrolledToVideo
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, index in
                currentIndexRelay.accept(index)

                let videos = videosRelay.value
                guard index < videos.count else { return }

                let video = videos[index]
                owner.loadStreamInfo(videoId: video.videoId, index: index, relay: streamInfoRelay, errorRelay: errorRelay)

                if index >= videos.count - 5, let next = nextCursor {
                    owner.repository.getVideos(next: next, limit: 20)
                        .asObservable()
                        .subscribe(onNext: { result in
                            var updatedVideos = videosRelay.value
                            updatedVideos.append(contentsOf: result.videos)
                            videosRelay.accept(updatedVideos)
                            nextCursor = result.nextCursor
                        }, onError: { error in
                            Logger.network.error("Failed to fetch more videos - \(error.localizedDescription)")
                        })
                        .disposed(by: owner.disposeBag)
                }
            })
            .disposed(by: disposeBag)

        input.likeButtonTapped
            .withUnretained(self)
            .flatMapLatest { owner, params in
                let videos = videosRelay.value
                guard params.index < videos.count else { return Observable<(Int, LikeVideoResponse)>.empty() }

                let video = videos[params.index]
                return owner.repository.likeVideo(videoId: video.videoId, likeStatus: !params.isLiked)
                    .asObservable()
                    .map { (params.index, $0) }
                    .catch { error in
                        Logger.network.error("Failed to like video - \(error.localizedDescription)")
                        errorRelay.accept("좋아요 처리에 실패했습니다")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, result in
                let (index, response) = result
                var videos = videosRelay.value
                guard index < videos.count else { return }

                let updatedVideo = Video(
                    videoId: videos[index].videoId,
                    title: videos[index].title,
                    description: videos[index].description,
                    thumbnailUrl: videos[index].thumbnailUrl,
                    availableQualities: videos[index].availableQualities,
                    viewCount: videos[index].viewCount,
                    likeCount: videos[index].likeCount + (response.like_status ? 1 : -1),
                    isLiked: response.like_status
                )

                videos[index] = updatedVideo
                videosRelay.accept(videos)

                likeUpdateRelay.accept((index, updatedVideo.likeCount, updatedVideo.isLiked))
            })
            .disposed(by: disposeBag)

        return Output(
            videos: videosRelay.asDriver(),
            currentVideoIndex: currentIndexRelay.asDriver(),
            streamInfo: streamInfoRelay.asDriver(onErrorDriveWith: .empty()),
            likeUpdated: likeUpdateRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다")
        )
    }

    private func loadStreamInfo(
        videoId: String,
        index: Int,
        relay: PublishRelay<(index: Int, streamInfo: VideoStreamInfo)>,
        errorRelay: PublishRelay<String>
    ) {
        repository.getStreamInfo(videoId: videoId)
            .asObservable()
            .subscribe(onNext: { streamInfo in
                relay.accept((index, streamInfo))
            }, onError: { error in
                Logger.network.error("Failed to fetch stream info - \(error.localizedDescription)")
                errorRelay.accept("스트리밍 정보를 불러오는데 실패했습니다")
            })
            .disposed(by: disposeBag)
    }
}
