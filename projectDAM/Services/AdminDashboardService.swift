
import Foundation

// MARK: - Models

struct AdminStatsResponse: Codable {
    let success: Bool?
    let data: AdminStatsData?
    let message: String?
}

struct AdminStatsData: Codable {
    let students: [MonthlyStat]
    let teachers: [MonthlyStat]
}

struct MonthlyStat: Codable, Identifiable {
    var id: String { month }
    let month: String
    let count: Int
}

// MARK: - Service Protocol

protocol AdminDashboardServiceProtocol {
    func fetchDashboardStats() async throws -> AdminStatsData
}

// MARK: - Service Implementation

class AdminDashboardService: AdminDashboardServiceProtocol {
    private let baseURL: String
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.baseURL = AppConfig.baseURL
        self.authService = authService
    }
    
    func fetchDashboardStats() async throws -> AdminStatsData {
        guard let url = URL(string: "\(baseURL)/admin/stats") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkError.unauthorized
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            let statsResponse = try decoder.decode(AdminStatsResponse.self, from: data)
            
            if statsResponse.success == true, let statsData = statsResponse.data {
                return statsData
            } else {
                throw NetworkError.serverError(httpResponse.statusCode, statsResponse.message ?? "Failed to fetch stats")
            }
            
        case 401:
            throw NetworkError.unauthorized
            
        case 403:
            throw NetworkError.serverError(403, "Admin privileges required")
            
        default:
            throw NetworkError.serverError(httpResponse.statusCode, "Server error")
        }
    }
}
