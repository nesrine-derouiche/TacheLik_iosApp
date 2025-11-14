import Foundation

// MARK: - Invitation Models
struct InvitationStats: Decodable {
    let success: Bool
    let totalInvitations: Int
    let validInvitations: Int
    let activeInvitations: Int
    let totalPoints: Int
    let pointPerInvitation: Int
    let pointPerPurchase: Int
}

// MARK: - Invitation Service Protocol
protocol InvitationServiceProtocol {
    func fetchInvitationStats(for userId: String) async throws -> InvitationStats
}

// MARK: - Invitation Service Implementation
final class InvitationService: InvitationServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func fetchInvitationStats(for userId: String) async throws -> InvitationStats {
        struct InvitationRequest: Encodable {
            let inviterId: String
        }
        
        let request = InvitationRequest(inviterId: userId)
        let requestData = try JSONEncoder().encode(request)
        
        if AppConfig.enableLogging {
            print("📡 [InvitationService] Fetching invitation stats for user: \(userId)")
        }
        
        do {
            let response: InvitationStats = try await networkService.request(
                endpoint: "/invitation/count",
                method: .POST,
                body: requestData,
                headers: authHeaders()
            )
            
            if AppConfig.enableLogging {
                print("✅ [InvitationService] Received invitation stats - Total: \(response.totalInvitations), Valid: \(response.validInvitations), Points: \(response.totalPoints)")
            }
            
            return response
        } catch {
            if AppConfig.enableLogging {
                print("❌ [InvitationService] Failed to fetch invitation stats: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else { return [:] }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }
}
