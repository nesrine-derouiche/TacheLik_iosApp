import Foundation

struct GiftCardRedeemRequest: Encodable {
    let code: String
    let userId: String
}

struct GiftCardRedeemResponse: Decodable {
    let message: String
    let success: Bool
    let credit: Int
    let Transaction: GiftCardTransaction
}

struct GiftCardTransaction: Decodable {
    let id: String
    let type: String
    let amount: Double
    let description: String
    let status: String
    let buyer_id: String
    let date: String
    let valid: Bool
}

protocol GiftCardServiceProtocol {
    func redeemGiftCard(code: String, userId: String) async throws -> GiftCardRedeemResponse
}

final class GiftCardService: GiftCardServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func redeemGiftCard(code: String, userId: String) async throws -> GiftCardRedeemResponse {
        let requestBody = GiftCardRedeemRequest(code: code, userId: userId)
        let requestData = try JSONEncoder().encode(requestBody)
        
        if AppConfig.enableLogging {
            print("📡 [GiftCardService] Redeeming gift card - Code: \(code)")
        }
        
        do {
            let response: GiftCardRedeemResponse = try await networkService.request(
                endpoint: "/gift-card/redeem",
                method: .POST,
                body: requestData,
                headers: authHeaders()
            )
            
            if AppConfig.enableLogging {
                print("✅ [GiftCardService] Gift card redeemed successfully - Transaction ID: \(response.Transaction.id), Credit: \(response.credit)")
            }
            
            return response
        } catch {
            if AppConfig.enableLogging {
                print("❌ [GiftCardService] Failed to redeem gift card: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else { return [:] }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }
}
