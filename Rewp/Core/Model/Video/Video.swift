//
//  Video.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation

struct Video {
    let videoId: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let availableQualities: [VideoQuality]
    let viewCount: Int
    let likeCount: Int
    let isLiked: Bool

    var formattedViewCount: String {
        if viewCount >= 10000 {
            return "\(viewCount / 10000)만"
        }
        return "\(viewCount)"
    }

    var formattedLikeCount: String {
        if likeCount >= 1000 {
            return "\(String(format: "%.1f", Double(likeCount) / 1000))K"
        }
        return "\(likeCount)"
    }
}
