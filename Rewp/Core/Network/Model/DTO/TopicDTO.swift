//
//  TopicDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import Foundation

struct TopicDTO: Codable {
    let title: String
    let content: String
    let date: String
    let link: String
}

struct TodayTopicsResponse: Codable {
    let data: [TopicDTO]
}

extension TopicDTO {
    func toTopicItem() -> TopicItem {
        return TopicItem(
            hashtag: title,
            description: content,
            date: date,
            link: link
        )
    }
}
