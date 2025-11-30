//
//  TeacherAnalyticsModels.swift
//  projectDAM
//
//  Created for dynamic teacher dashboard analytics
//

import Foundation

// MARK: - Teacher Analytics Response
struct TeacherAnalyticsResponse: Codable {
    let success: Bool
    let message: String?
    let data: TeacherAnalyticsData?
    let timeframe: String?
    let startDate: String?
    let endDate: String?
    let isLifetime: Bool?
    let teacherId: String?
}

// MARK: - Teacher Analytics Data
struct TeacherAnalyticsData: Codable {
    // Revenue metrics
    let totalRevenue: Double?
    let totalSales: Int?
    let averagePrice: Double?
    let pendingPayout: Double?
    let contractPercentage: Double?
    let totalWithdrawn: Double?
    
    // Course performance
    let totalEnrollments: Int?
    
    // Student engagement
    let activeStudents: Int?
    let videoViews: Int?
    
    // Revenue breakdown
    let revenueByMonth: [RevenueByMonth]?
    
    // Top performing courses
    let topCourses: [TopCourse]?
    
    // Recent transactions
    let recentTransactions: [RecentTransaction]?
    
    // Computed property for total students (using totalEnrollments)
    var totalStudents: Int {
        return totalEnrollments ?? 0
    }
}

// MARK: - Revenue By Month
struct RevenueByMonth: Codable {
    let month: String
    let revenue: Double
    let sales: Int
}

// MARK: - Top Course
struct TopCourse: Codable {
    let id: String
    let name: String
    let revenue: Double
    let enrollments: Int
}

// MARK: - Recent Transaction
struct RecentTransaction: Codable {
    let id: String
    let amount: Double
    let date: String
    let courseName: String
    let studentName: String
    let status: String
    
    /// Get initials from student name (first letter of each word)
    var studentInitials: String {
        let words = studentName.split(separator: " ")
        let initials = words.prefix(3).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "?" : initials
    }
    
    /// Get relative time string from date
    var timeAgo: String {
        // Try to parse the date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let transactionDate = dateFormatter.date(from: date) else {
            // Try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            guard let transactionDate = dateFormatter.date(from: date) else {
                return "recently"
            }
            return relativeTime(from: transactionDate)
        }
        return relativeTime(from: transactionDate)
    }
    
    private func relativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)w ago"
        }
    }
    
    /// Activity type based on transaction type
    var activityAction: String {
        return "enrolled in course"
    }
    
    /// Icon for the activity
    var activityIcon: String {
        return "checkmark.circle.fill"
    }
}

// MARK: - Teacher Course Summary Response
struct TeacherCourseSummaryResponse: Codable {
    let success: Bool
    let message: String?
    let data: [CourseSummary]?
    let teacherId: String?
}

// MARK: - Course Summary
struct CourseSummary: Codable {
    let id: String
    let name: String
    let image: String?
    let description: String?
    let price: Double?
    let level: String?
    let studentCount: Int?
    let approvalStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, image, description, price, level, studentCount
        case approvalStatus = "approval_status"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        studentCount = try container.decodeIfPresent(Int.self, forKey: .studentCount)
        approvalStatus = try container.decodeIfPresent(String.self, forKey: .approvalStatus)
    }
}
