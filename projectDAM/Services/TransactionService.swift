import Foundation

// MARK: - Transaction Service Protocol
protocol TransactionServiceProtocol {
    func fetchTransactions(userId: String, page: Int, limit: Int) async throws -> PaginatedTransactionsResponse
}

// MARK: - Transaction Service Implementation
final class TransactionService: TransactionServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func fetchTransactions(userId: String, page: Int, limit: Int) async throws -> PaginatedTransactionsResponse {
        struct TransactionsRequest: Encodable {
            let userId: String
            let page: Int
            let limit: Int
        }
        
        let request = TransactionsRequest(userId: userId, page: page, limit: limit)
        let requestData = try JSONEncoder().encode(request)
        
        if AppConfig.enableLogging {
            print("📡 [TransactionService] Fetching transactions page: \(page), limit: \(limit) for user: \(userId)")
        }
        do {
            let response: PaginatedTransactionsResponse = try await networkService.request(
                endpoint: "/payment-transaction/transactions-paginated",
                method: .POST,
                body: requestData,
                headers: authHeaders()
            )
            if AppConfig.enableLogging {
                print("✅ [TransactionService] Received \(response.transactions.count) transactions (page \(response.page)/\(response.totalPages))")
                let entries = response.transactions.map { transaction in
                    "{id: \(transaction.id), type: \(transaction.type), amount: \(transaction.amount), status: \(transaction.status)}"
                }
                print("📦 [TransactionService] Transactions: [\(entries.joined(separator: ", "))]")
            }
            return response
        } catch {
            if AppConfig.enableLogging {
                print("❌ [TransactionService] Failed to fetch transactions: \(error.localizedDescription)")
                if let networkError = error as? NetworkError {
                    print("❌ [TransactionService] Network error detail: \(networkError)")
                }
            }
            throw error
        }
    }
    
    private func authHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else { return [:] }
        return ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
    }
}
