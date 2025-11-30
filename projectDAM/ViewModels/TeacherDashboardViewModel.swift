//
//  TeacherDashboardViewModel.swift
//  projectDAM
//
//  Created for dynamic teacher dashboard analytics
//

import Foundation
import Combine

// MARK: - Teacher Dashboard ViewModel
@MainActor
class TeacherDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // Revenue Metrics
    @Published var totalRevenue: Double = 0.0
    @Published var totalSales: Int = 0
    @Published var averagePrice: Double = 0.0
    @Published var pendingPayout: Double = 0.0
    @Published var contractPercentage: Double = 65.0
    @Published var totalWithdrawn: Double = 0.0
    
    // Course & Student Metrics
    @Published var totalStudents: Int = 0
    @Published var activeStudents: Int = 0
    @Published var activeCourses: Int = 0
    @Published var videoViews: Int = 0
    
    // Quick Action Badges
    @Published var pendingQuestions: Int = 0
    
    // Lists
    @Published var topCourses: [TopCourse] = []
    @Published var recentTransactions: [RecentTransaction] = []
    @Published var revenueByMonth: [RevenueByMonth] = []
    
    // State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    // MARK: - Computed Properties
    var formattedRevenue: String {
        if totalRevenue >= 1000 {
            return String(format: "%.1fK TND", totalRevenue / 1000)
        }
        return String(format: "%.0f TND", totalRevenue)
    }
    
    var formattedPendingPayout: String {
        return String(format: "%.0f TND", pendingPayout)
    }
    
    var formattedWithdrawn: String {
        return String(format: "%.0f TND", totalWithdrawn)
    }
    
    var teacherEarningsPercentage: Double {
        return 100 - contractPercentage
    }
    
    // MARK: - Dependencies
    private let analyticsService: TeacherAnalyticsServiceProtocol
    
    // MARK: - Initialization
    init(analyticsService: TeacherAnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Fetch Dashboard Data
    func fetchDashboardData() {
        Task {
            await loadDashboardData()
        }
    }
    
    private func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        print("🔄 [TeacherDashboardViewModel] Loading dashboard data...")
        
        do {
            // Fetch analytics data
            let analyticsData = try await analyticsService.fetchAnalytics(timeframe: "30d")
            
            // Revenue Metrics
            self.totalRevenue = analyticsData.totalRevenue ?? 0.0
            self.totalSales = analyticsData.totalSales ?? 0
            self.averagePrice = analyticsData.averagePrice ?? 0.0
            self.pendingPayout = analyticsData.pendingPayout ?? 0.0
            self.contractPercentage = analyticsData.contractPercentage ?? 65.0
            self.totalWithdrawn = analyticsData.totalWithdrawn ?? 0.0
            
            // Student & Engagement Metrics
            self.totalStudents = analyticsData.totalEnrollments ?? 0
            self.activeStudents = analyticsData.activeStudents ?? 0
            self.videoViews = analyticsData.videoViews ?? 0
            
            // Lists
            self.topCourses = analyticsData.topCourses ?? []
            self.recentTransactions = analyticsData.recentTransactions ?? []
            self.revenueByMonth = analyticsData.revenueByMonth ?? []
            
            // Fetch course summary to get active courses count
            let courseSummary = try await analyticsService.fetchCourseSummary()
            self.activeCourses = courseSummary.count
            
            print("✅ [TeacherDashboardViewModel] Dashboard data loaded successfully")
            print("   - Total Revenue: \(self.totalRevenue) TND")
            print("   - Total Sales: \(self.totalSales)")
            print("   - Total Students: \(self.totalStudents)")
            print("   - Active Students: \(self.activeStudents)")
            print("   - Active Courses: \(self.activeCourses)")
            print("   - Video Views: \(self.videoViews)")
            print("   - Pending Payout: \(self.pendingPayout) TND")
            
            isLoading = false
            
        } catch let error as NetworkError {
            isLoading = false
            hasError = true
            
            switch error {
            case .unauthorized:
                errorMessage = "Please log in to view dashboard"
                print("❌ [TeacherDashboardViewModel] Unauthorized")
                
            case .serverError(let code, let message):
                errorMessage = message ?? "Server error \(code)"
                print("❌ [TeacherDashboardViewModel] Server error \(code): \(message ?? "Unknown")")
                
            case .invalidResponse:
                errorMessage = "Network error. Please check your connection."
                print("❌ [TeacherDashboardViewModel] Invalid response")
                
            case .decodingError:
                errorMessage = "Failed to process data"
                print("❌ [TeacherDashboardViewModel] Decoding error")
                
            case .invalidURL:
                errorMessage = "Invalid URL configuration"
                print("❌ [TeacherDashboardViewModel] Invalid URL")
                
            case .noData:
                errorMessage = "No data received"
                print("❌ [TeacherDashboardViewModel] No data")
            }
            
        } catch {
            isLoading = false
            hasError = true
            errorMessage = error.localizedDescription
            print("❌ [TeacherDashboardViewModel] Error: \(error)")
        }
    }
    
    // MARK: - Refresh Data
    func refreshData() {
        fetchDashboardData()
    }
}
