//
//  Date+RelativeTime.swift
//  Rewp
//
//  Created by 금가경 on 01/02/26.
//

import Foundation

extension Date {
    func toRelativeTimeString() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)

        if let year = components.year, year > 0 {
            return "\(year)년 전"
        }

        if let month = components.month, month > 0 {
            return "\(month)달 전"
        }

        if let day = components.day, day > 0 {
            let weeks = day / 7
            if weeks > 0 {
                return "\(weeks)주 전"
            }
            return "\(day)일 전"
        }

        if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        }

        if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        }

        return "방금 전"
    }
}

extension String {
    func toDate() -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: self) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: self)
    }

    func toRelativeTimeString() -> String {
        return toDate()?.toRelativeTimeString() ?? self
    }
}
