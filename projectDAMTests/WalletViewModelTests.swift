#if canImport(XCTest)
import XCTest
import Combine
@testable import projectDAM

// MARK: - Mocks & Extensions for Testing

// Extension to allow creating PaymentTransaction manually since it lacks a public memberwise init
extension PaymentTransaction {
    init(id: String, type: String, amount: Double, date: Date, description: String, status: String) {
        // We can't access let properties directly if they are not mutable, but 
        // we can use a workaround by decoding from JSON or using unsafe bitcast if strict,
        // OR simpler: since we are in strict Swift, we can't inject into 'let' props without an init.
        // We will define a local mock definition or try to decode from JSON as a workaround.
        
        let json: [String: Any] = [
            "id": id,
            "type": type,
            "amount": amount,
            "date": ISO8601DateFormatter().string(from: date),
            "description": description,
            "status": status
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoded = try! JSONDecoder().decode(PaymentTransaction.self, from: data)
        
        self = decoded
    }
}

// Extension for InvitationStats
extension InvitationStats {
    init(success: Bool, totalInvitations: Int, validInvitations: Int, activeInvitations: Int, totalPoints: Int, pointPerInvitation: Int, pointPerPurchase: Int) {
        let json: [String: Any] = [
            "success": success,
            "totalInvitations": totalInvitations,
            "validInvitations": validInvitations,
            "activeInvitations": activeInvitations,
            "totalPoints": totalPoints,
            "pointPerInvitation": pointPerInvitation,
            "pointPerPurchase": pointPerPurchase
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoded = try! JSONDecoder().decode(InvitationStats.self, from: data)
        self = decoded
    }
}

class MockTransactionService: TransactionServiceProtocol {
    var resultToReturn: Result<PaginatedTransactionsResponse, Error>?
    
    func fetchTransactions(userId: String, start: Int) async throws -> PaginatedTransactionsResponse {
        guard let result = resultToReturn else {
            throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

class MockInvitationService: InvitationServiceProtocol {
    var resultToReturn: Result<InvitationStats, Error>?
    
    func fetchInvitationStats(for userId: String) async throws -> InvitationStats {
        guard let result = resultToReturn else {
            throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        switch result {
        case .success(let stats):
            return stats
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Tests

@MainActor
final class WalletViewModelTests: XCTestCase {
    
    var viewModel: WalletViewModel!
    var mockTransactionService: MockTransactionService!
    var mockInvitationService: MockInvitationService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockTransactionService = MockTransactionService()
        mockInvitationService = MockInvitationService()
        viewModel = WalletViewModel(transactionService: mockTransactionService, invitationService: mockInvitationService)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockTransactionService = nil
        mockInvitationService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoadInitialTransactions_Success() async {
        // Given
        let transaction = PaymentTransaction(
            id: "t1",
            type: "deposit",
            amount: 50.0,
            date: Date(),
            description: "Test Deposit",
            status: "completed"
        )
        let response = PaginatedTransactionsResponse(
            transactions: [transaction],
            total: 1,
            page: 1,
            limit: 10,
            totalPages: 1,
            success: true
        )
        mockTransactionService.resultToReturn = .success(response)
        
        // When
        await viewModel.loadInitialTransactions(for: "user123")
        
        // Then
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.first?.id, "t1")
        XCTAssertFalse(viewModel.isInitialLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadInitialTransactions_Failure() async {
        // Given
        let error = NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Network failure"])
        mockTransactionService.resultToReturn = .failure(error)
        
        // When
        await viewModel.loadInitialTransactions(for: "user123")
        
        // Then
        XCTAssertTrue(viewModel.transactions.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Network failure") // Depends on localizedDescription
        XCTAssertFalse(viewModel.isInitialLoading)
    }
    
    func testPagination() async {
        // Given initial load with 2 pages
        let t1 = PaymentTransaction(id: "1", type: "a", amount: 10, date: Date(), description: "d", status: "s")
        let firstPage = PaginatedTransactionsResponse(
            transactions: [t1],
            total: 2,
            page: 0,
            limit: 1,
            totalPages: 2,
            success: true
        )
        mockTransactionService.resultToReturn = .success(firstPage)
        
        await viewModel.loadInitialTransactions(for: "u1")
        
        // Verify first page state
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertTrue(viewModel.hasMorePages)
        
        // Prepare second page
        let t2 = PaymentTransaction(id: "2", type: "b", amount: 20, date: Date(), description: "d2", status: "s")
        let secondPage = PaginatedTransactionsResponse(
            transactions: [t2],
            total: 2,
            page: 1,
            limit: 1,
            totalPages: 2,
            success: true
        )
        mockTransactionService.resultToReturn = .success(secondPage)
        
        // When loading next page
        await viewModel.loadNextPage()
        
        // Then
        XCTAssertEqual(viewModel.transactions.count, 2)
        XCTAssertFalse(viewModel.hasMorePages)
    }
    
    func testAvailableInvitations() async {
        // Given
        let stats = InvitationStats(
            success: true,
            totalInvitations: 10,
            validInvitations: 5,
            activeInvitations: 2,
            totalPoints: 100,
            pointPerInvitation: 10,
            pointPerPurchase: 5
        )
        mockInvitationService.resultToReturn = .success(stats)
        
        // When
        await viewModel.loadInvitationStats(for: "u1")
        
        // Then
        XCTAssertNotNil(viewModel.invitationStats)
        XCTAssertEqual(viewModel.invitationStats?.totalPoints, 100)
        XCTAssertNil(viewModel.invitationErrorMessage)
        XCTAssertFalse(viewModel.isLoadingInvitations)
    }
}
#endif
