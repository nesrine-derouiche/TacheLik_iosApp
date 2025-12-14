import Foundation

protocol HomeDashboardServiceProtocol {
    func fetchStudentHome() async throws -> StudentHomeData
    func fetchTeacherHome(teacherId: String?) async throws -> TeacherHomeData
}

final class HomeDashboardService: HomeDashboardServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol

    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }

    func fetchStudentHome() async throws -> StudentHomeData {
        let response: StudentHomeResponse = try await networkService.request(
            endpoint: "/student-dashboard/home",
            method: .GET,
            body: nil,
            headers: authHeaders()
        )
        guard response.success, let data = response.data else {
            throw NetworkError.serverError(500, response.message ?? "Failed to load dashboard")
        }
        return data
    }

    func fetchTeacherHome(teacherId: String?) async throws -> TeacherHomeData {
        let endpoint: String
        if let teacherId, !teacherId.isEmpty {
            endpoint = "/teacher-dashboard/home?teacherId=\(teacherId)"
        } else {
            endpoint = "/teacher-dashboard/home"
        }

        let response: TeacherHomeResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: authHeaders()
        )
        guard response.success, let data = response.data else {
            throw NetworkError.serverError(500, response.message ?? "Failed to load dashboard")
        }
        return data
    }

    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken(), !token.isEmpty else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}
