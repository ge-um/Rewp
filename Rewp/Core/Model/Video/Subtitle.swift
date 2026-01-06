//
//  Subtitle.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation

struct Subtitle {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
}

struct SubtitleTrack {
    let language: String
    let displayName: String
    let subtitles: [Subtitle]
}
