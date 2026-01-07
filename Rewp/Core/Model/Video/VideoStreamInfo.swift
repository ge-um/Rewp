//
//  VideoStreamInfo.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation

struct VideoStreamInfo {
    let videoId: String
    let masterPlaylistUrl: String
    let qualities: [QualityStream]
    let subtitles: [SubtitleInfo]

    struct QualityStream {
        let quality: VideoQuality
        let url: String
    }
}

struct SubtitleInfo {
    let language: String
    let displayName: String
    let url: String
    let isDefault: Bool
}
