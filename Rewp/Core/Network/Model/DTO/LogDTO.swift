//
//  LogDTO.swift
//  Rewp
//
//  Created by 금가경 on 12/27/25.
//

import Foundation

struct LogItem: Codable {
    let date: String
    let name: String
    let method: String
    let route_path: String
    let body: String
    let contentType: String
    let status_code: String
}

struct LogResponse: Codable {
    let count: Int
    let logs: [LogItem]
}
