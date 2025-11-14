import Foundation
import Combine

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var transactions: [PaymentTransaction] = []
    @Published private(set) var isInitialLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var hasMorePages: Bool = false
    @Published var errorMessage: String?
    
    private let transactionService: TransactionServiceProtocol
    private var currentUserId: String?
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private let pageSize: Int = 10
    
    init(transactionService: TransactionServiceProtocol) {
        self.transactionService = transactionService
    }
    
    func loadInitialTransactions(for userId: String) async {
        guard !userId.isEmpty else { return }
        if currentUserId != userId {
            resetState(for: userId)
        } else if !transactions.isEmpty {
            return
        }
        await fetchTransactions(page: 1, reset: true)
    }
    
    func refreshTransactions(for userId: String) async {
        guard !userId.isEmpty else { return }
        resetState(for: userId)
        await fetchTransactions(page: 1, reset: true)
    }
    
    func loadNextPage() async {
        guard !isLoadingMore,
              hasMorePages,
              let userId = currentUserId else { return }
        await fetchTransactions(page: currentPage + 1, reset: false, userIdOverride: userId)
    }
    
    func hasLoadedTransactions(for userId: String) -> Bool {
        currentUserId == userId && !transactions.isEmpty
    }
    
    private func resetState(for userId: String) {
        currentUserId = userId
        currentPage = 1
        totalPages = 1
        hasMorePages = false
        transactions.removeAll()
        errorMessage = nil
    }
    
    private func fetchTransactions(page: Int, reset: Bool, userIdOverride: String? = nil) async {
        guard let userId = userIdOverride ?? currentUserId else { return }
        if reset {
            isInitialLoading = true
        } else {
            isLoadingMore = true
        }
        errorMessage = nil
        
        do {
            let response = try await transactionService.fetchTransactions(userId: userId, page: page, limit: pageSize)
            if reset {
                transactions = response.transactions
            } else {
                transactions.append(contentsOf: response.transactions)
            }
            currentPage = response.page
            totalPages = response.totalPages
            hasMorePages = currentPage < totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isInitialLoading = false
        isLoadingMore = false
    }
}
