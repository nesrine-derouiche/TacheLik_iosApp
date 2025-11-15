import Foundation

struct D17PaymentResponse: Decodable {
    let message: String
    let success: Bool
    let Transaction: D17PaymentTransaction
}

struct D17PaymentTransaction: Decodable {
    let id: String
    let type: String
    let amount: Double
    let description: String
    let payment_confirmation_code: String?
    let d17_byuer_phone: String?
    let valid: Bool
    let status: String
    let buyer_id: String
    let updated_at: String?
    let auth_receipt_picture: D17ReceiptBuffer?
    let bought_store_product_id: String?
    let bought_course_price: String?
    let achievement_type: String
    let date: String
    let admin_granted_free: Bool
}

struct D17ReceiptBuffer: Decodable {
    let type: String
    let data: [UInt8]
}

protocol D17PaymentServiceProtocol {
    func requestD17Payment(
        userId: String,
        amount: Int,
        authNumber: String,
        senderPhone: String,
        receiptImage: Data?,
        receiptFileName: String?,
        receiptMimeType: String?
    ) async throws -> D17PaymentResponse
}

final class D17PaymentService: D17PaymentServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func requestD17Payment(
        userId: String,
        amount: Int,
        authNumber: String,
        senderPhone: String,
        receiptImage: Data?,
        receiptFileName: String?,
        receiptMimeType: String?
    ) async throws -> D17PaymentResponse {
        var multipart = MultipartFormData()
        multipart.addField(name: "amount", value: String(amount))
        multipart.addField(name: "auth_nb", value: authNumber)
        multipart.addField(name: "senderPhone", value: senderPhone)
        multipart.addField(name: "userId", value: userId)
        
        if let imageData = receiptImage,
           let fileName = receiptFileName,
           let mimeType = receiptMimeType {
            multipart.addFile(
                fieldName: "auth_receipt_picture",
                fileName: fileName,
                mimeType: mimeType,
                data: imageData
            )
        }
        
        if AppConfig.enableLogging {
            print("📡 [D17PaymentService] Requesting D17 payment - amount: \(amount), phone: \(senderPhone), auth_nb: \(authNumber)")
        }
        
        do {
            let response: D17PaymentResponse = try await networkService.upload(
                endpoint: "/d17-payment/request-d17?userId=\(userId)",
                method: .POST,
                multipart: multipart,
                headers: authHeaders()
            )
            
            if AppConfig.enableLogging {
                print("✅ [D17PaymentService] D17 payment request created - Transaction ID: \(response.Transaction.id)")
            }
            
            return response
        } catch {
            if AppConfig.enableLogging {
                print("❌ [D17PaymentService] Failed to request D17 payment: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}
