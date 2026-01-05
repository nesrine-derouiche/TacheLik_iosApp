import Foundation
import Combine
import SwiftUI

// MARK: - View Model

@MainActor
final class AdminHomeViewModel: ObservableObject {
    
    // MARK: - State
    
    enum ViewState {
        case idle
        case loading
        case content(AdminStatsData)
        case error(String)
    }
    
    @Published private(set) var viewState: ViewState = .idle
    @Published var isOnline: Bool = true // Placeholder for network monitoring
    
    // MARK: - Dependencies
    
    private let service: AdminDashboardServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(service: AdminDashboardServiceProtocol = DIContainer.shared.adminDashboardService) {
        self.service = service
    }
    
    // MARK: - Actions
    
    func send(action: Action) {
        switch action {
        case .loadData:
            loadData()
        case .refresh:
            Task { await refresh() }
        }
    }
    
    enum Action {
        case loadData
        case refresh
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        guard !isLoading else { return }
        viewState = .loading
        
        Task {
            do {
                let data = try await service.fetchDashboardStats()
                viewState = .content(data)
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
    
    private func refresh() async {
        // When refreshing, we typically want to keep showing content or show a specific refreshing state.
        // For simplicity reusing loading or just silenty updating if using pull-to-refresh logic in view.
        // But here we'll just fetch.
        
        do {
            let data = try await service.fetchDashboardStats()
            viewState = .content(data)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    private var isLoading: Bool {
        if case .loading = viewState { return true }
        return false
    }
}
