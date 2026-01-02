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
}
