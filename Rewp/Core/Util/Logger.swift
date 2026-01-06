//
//  Logger.swift
//  Rewp
//
//  Created by 금가경 on 01/01/26.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.rewp"

    static let auth = Logger(subsystem: subsystem, category: "Authentication")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let token = Logger(subsystem: subsystem, category: "TokenManagement")

    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let chat = Logger(subsystem: subsystem, category: "Chat")
    static let socket = Logger(subsystem: subsystem, category: "Socket")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
    static let fcm = Logger(subsystem: subsystem, category: "FCM")
    static let storage = Logger(subsystem: subsystem, category: "Storage")
}
