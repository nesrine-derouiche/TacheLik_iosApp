import Foundation

// MARK: - Cash Payment Models
struct CashPaymentRequest: Encodable {
    let amount: String
    let userId: String
    let senderPhone: String
}

struct CashPaymentResponse: Decodable {
    let message: String
    let success: Bool
    let Transaction: CashPaymentTransaction
}

struct CashPaymentTransaction: Decodable {
    let id: String
    let type: String
    let amount: Double
    let description: String
    let d17_byuer_phone: String
    let valid: Bool
    let status: String
    let buyer_id: String
    let updated_at: String?
    let payment_confirmation_code: String?
    let auth_receipt_picture: String?
    let bought_store_product_id: String?
    let bought_course_price: String?
    let achievement_type: String
    let date: String
    let admin_granted_free: Bool
}

// MARK: - Cash Payment Service Protocol
protocol CashPaymentServiceProtocol {
    func requestCashPayment(amount: Int, userId: String, senderPhone: String) async throws -> CashPaymentResponse
}

// MARK: - Cash Payment Service Implementation
final class CashPaymentService: CashPaymentServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func requestCashPayment(amount: Int, userId: String, senderPhone: String) async throws -> CashPaymentResponse {
        let request = CashPaymentRequest(
            amount: String(amount),
            userId: userId,
            senderPhone: senderPhone
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        if AppConfig.enableLogging {
            print("📡 [CashPaymentService] Requesting cash payment - Amount: \(amount), Phone: \(senderPhone)")
        }
        
        do {
            let response: CashPaymentResponse = try await networkService.request(
                endpoint: "/cash-payment/request-cash",
                method: .POST,
                body: requestData,
                headers: authHeaders()
            )
            
            if AppConfig.enableLogging {
                print("✅ [CashPaymentService] Cash payment request successful - Transaction ID: \(response.Transaction.id)")
            }
            
            return response
        } catch {
            if AppConfig.enableLogging {
                print("❌ [CashPaymentService] Failed to request cash payment: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else { return [:] }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }
}
