//
//  VideoQuality.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import Foundation

enum VideoQuality: String, CaseIterable {
    case p1080 = "1080p"
    case p720 = "720p"
    case p480 = "480p"

    var displayName: String {
        return rawValue
    }

    var bitrate: Int {
        switch self {
        case .p1080: return 5000000
        case .p720: return 2500000
        case .p480: return 1000000
        }
    }
}
