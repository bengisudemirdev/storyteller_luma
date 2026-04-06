//
//  AppLogger.swift
//  Tutarlı, event tabanlı loglar (token / tam gövde / tam masal metni yazılmaz).
//

import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Olia"
    private static let log = Logger(subsystem: subsystem, category: "Olia")

    private static func line(level: OSLogType, event: String, fields: [String: String]) {
        let tail = fields.isEmpty ? "" : " | " + fields.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        log.log(level: level, "\(event, privacy: .public)\(tail, privacy: .public)")
    }

    static func debug(_ event: String, _ fields: [String: String] = [:]) {
        line(level: .debug, event: event, fields: fields)
    }

    static func info(_ event: String, _ fields: [String: String] = [:]) {
        line(level: .info, event: event, fields: fields)
    }

    static func warning(_ event: String, _ fields: [String: String] = [:]) {
        line(level: .default, event: event, fields: fields)
    }

    static func error(_ event: String, _ fields: [String: String] = [:]) {
        line(level: .error, event: event, fields: fields)
    }
}
