import Foundation
import SwiftUI

struct ReelRelativeTimestampView: View {
    let createdAt: String

    private static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoWithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    var body: some View {
        if let createdDate = Self.parseCreatedAt(createdAt) {
            TimelineView(.periodic(from: Date(), by: 60)) { context in
                Text(Self.instagramRelativeString(from: createdDate, to: context.date))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityLabel(Self.accessibilityString(from: createdDate, to: context.date))
            }
        }
    }

    static func parseCreatedAt(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        if let date = isoWithFractionalSeconds.date(from: value) {
            return date
        }
        return isoWithoutFractionalSeconds.date(from: value)
    }

    static func instagramRelativeString(from date: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))

        if seconds < 10 {
            return "Just now"
        }
        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }

        let days = hours / 24
        if days == 1 {
            return "Yesterday"
        }
        if days < 7 {
            return "\(days)d ago"
        }

        let weeks = days / 7
        if weeks < 5 {
            return "\(weeks)w ago"
        }

        let months = days / 30
        if months < 12 {
            return "\(months)mo ago"
        }

        let years = days / 365
        return "\(years)y ago"
    }

    private static func accessibilityString(from date: Date, to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
