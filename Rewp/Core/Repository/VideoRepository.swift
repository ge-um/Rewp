//
//  VideoRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation
import RxSwift

protocol VideoRepository {
    func getVideos(next: String?, limit: Int) -> Single<(videos: [Video], nextCursor: String?)>
    func getStreamInfo(videoId: String) -> Single<VideoStreamInfo>
    func likeVideo(videoId: String, likeStatus: Bool) -> Single<LikeVideoResponse>
}

final class VideoRepositoryImpl: VideoRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func getVideos(next: String?, limit: Int) -> Single<(videos: [Video], nextCursor: String?)> {
        return authService.authenticatedRequest(VideoRouter.getVideos(next: next, limit: limit))
            .map { (response: GetVideosResponse) in
                let videos = response.data.map { $0.toDomain() }
                return (videos: videos, nextCursor: response.next_cursor)
            }
    }

    func getStreamInfo(videoId: String) -> Single<VideoStreamInfo> {
        return authService.authenticatedRequest(VideoRouter.getStream(videoId: videoId))
            .map { (response: GetVideoStreamResponse) in
                response.toDomain()
            }
    }

    func likeVideo(videoId: String, likeStatus: Bool) -> Single<LikeVideoResponse> {
        return authService.authenticatedRequest(VideoRouter.likeVideo(videoId: videoId, likeStatus: likeStatus))
    }
}
