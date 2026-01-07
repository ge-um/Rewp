//
//  VideoDTO.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation

struct GetVideosResponse: Decodable {
    let data: [VideoDTO]
    let next_cursor: String?
}

struct VideoDTO: Decodable {
    let video_id: String
    let file_name: String
    let title: String
    let description: String
    let duration: Double
    let thumbnail_url: String
    let available_qualities: [String]
    let view_count: Int
    let like_count: Int
    let is_liked: Bool
    let createdAt: String
}

extension VideoDTO {
    func toDomain() -> Video {
        let qualities = available_qualities.compactMap { qualityString -> VideoQuality? in
            switch qualityString {
            case "1080p": return .p1080
            case "720p": return .p720
            case "480p": return .p480
            default: return nil
            }
        }

        let baseURL = NetworkConfig.baseURL.replacingOccurrences(of: "/v1", with: "")
        let absoluteThumbnailUrl = thumbnail_url.hasPrefix("http")
            ? thumbnail_url
            : baseURL + thumbnail_url

        return Video(
            videoId: video_id,
            title: title,
            description: description,
            thumbnailUrl: absoluteThumbnailUrl,
            availableQualities: qualities,
            viewCount: view_count,
            likeCount: like_count,
            isLiked: is_liked
        )
    }
}

struct GetVideoStreamResponse: Decodable {
    let video_id: String
    let stream_url: String
    let qualities: [QualityStreamDTO]
    let subtitles: [SubtitleInfoDTO]
}

struct QualityStreamDTO: Decodable {
    let quality: String
    let url: String
}

struct SubtitleInfoDTO: Decodable {
    let language: String
    let name: String
    let is_default: Bool
    let url: String
}

extension GetVideoStreamResponse {
    func toDomain() -> VideoStreamInfo {
        let baseURL = NetworkConfig.baseURL

        func toAbsoluteURL(_ path: String) -> String {
            if path.hasPrefix("http://") || path.hasPrefix("https://") {
                return path
            }
            return baseURL + path
        }

        let qualityStreams = qualities.compactMap { dto -> VideoStreamInfo.QualityStream? in
            guard let quality = VideoQuality(rawValue: dto.quality) else { return nil }
            return VideoStreamInfo.QualityStream(quality: quality, url: toAbsoluteURL(dto.url))
        }

        let subtitleInfos = subtitles.map { dto in
            SubtitleInfo(
                language: dto.language,
                displayName: dto.name,
                url: dto.url,
                isDefault: dto.is_default
            )
        }

        return VideoStreamInfo(
            videoId: video_id,
            masterPlaylistUrl: toAbsoluteURL(stream_url),
            qualities: qualityStreams,
            subtitles: subtitleInfos
        )
    }
}

struct LikeVideoRequest: Encodable {
    let like_status: Bool
}

struct LikeVideoResponse: Decodable {
    let like_status: Bool
}
