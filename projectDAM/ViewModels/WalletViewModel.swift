import Foundation
import Combine

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var transactions: [PaymentTransaction] = []
    @Published private(set) var isInitialLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var hasMorePages: Bool = false
    @Published var errorMessage: String?
    
    // Invitation stats
    @Published private(set) var invitationStats: InvitationStats?
    @Published private(set) var isLoadingInvitations: Bool = false
    @Published var invitationErrorMessage: String?
    
    private let transactionService: TransactionServiceProtocol
    private let invitationService: InvitationServiceProtocol
    private var currentUserId: String?
    private var currentStartIndex: Int = 0
    private var totalPages: Int = 1
    private let serverPageSize: Int = 5
    
    init(transactionService: TransactionServiceProtocol, invitationService: InvitationServiceProtocol) {
        self.transactionService = transactionService
        self.invitationService = invitationService
    }
    
    func loadInitialTransactions(for userId: String) async {
        guard !userId.isEmpty else { return }
        if currentUserId != userId {
            resetState(for: userId)
        } else if !transactions.isEmpty {
            return
        }
        await fetchTransactions(start: 0, reset: true)
    }
    
    func refreshTransactions(for userId: String) async {
        guard !userId.isEmpty else { return }
        resetState(for: userId)
        await fetchTransactions(start: 0, reset: true)
    }
    
    func loadNextPage() async {
        guard !isLoadingMore,
              hasMorePages,
              let userId = currentUserId else { return }
        let nextStart = currentStartIndex + serverPageSize
        await fetchTransactions(start: nextStart, reset: false, userIdOverride: userId)
    }
    
    func hasLoadedTransactions(for userId: String) -> Bool {
        currentUserId == userId && !transactions.isEmpty
    }
    
    func loadInvitationStats(for userId: String) async {
        guard !userId.isEmpty else { return }
        isLoadingInvitations = true
        invitationErrorMessage = nil
        
        do {
            let stats = try await invitationService.fetchInvitationStats(for: userId)
            invitationStats = stats
        } catch {
            invitationErrorMessage = error.localizedDescription
        }
        
        isLoadingInvitations = false
    }
    
    func refreshInvitationStats(for userId: String) async {
        await loadInvitationStats(for: userId)
    }
    
    private func resetState(for userId: String) {
        currentUserId = userId
        currentStartIndex = 0
        totalPages = 1
        hasMorePages = false
        transactions.removeAll()
        errorMessage = nil
    }
    
    private func fetchTransactions(start: Int, reset: Bool, userIdOverride: String? = nil) async {
        guard let userId = userIdOverride ?? currentUserId else { return }
        if reset {
            isInitialLoading = true
        } else {
            isLoadingMore = true
        }
        errorMessage = nil
        
        do {
            let response = try await transactionService.fetchTransactions(userId: userId, start: start)
            if reset {
                transactions = response.transactions
            } else {
                transactions.append(contentsOf: response.transactions)
            }
            currentStartIndex = start
            totalPages = response.totalPages
            hasMorePages = response.page < response.totalPages - 1
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isInitialLoading = false
        isLoadingMore = false
    }
}
