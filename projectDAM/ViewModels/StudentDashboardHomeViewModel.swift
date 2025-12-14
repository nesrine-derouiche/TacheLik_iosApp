import Foundation
import Combine

@MainActor
final class StudentDashboardHomeViewModel: ObservableObject {

    enum UiState: Equatable {
        case loading
        case content(home: StudentHomeData, savedAt: Date?)
        case error(message: String, cachedHome: StudentHomeData?, isOffline: Bool, cachedSavedAt: Date?)
    }

    @Published private(set) var uiState: UiState = .loading
    @Published private(set) var isOnline: Bool = true

    private let service: HomeDashboardServiceProtocol
    private let cache: HomeCacheStore
    private let networkMonitor: NetworkMonitor

    private var cancellables = Set<AnyCancellable>()
    private var autoRefreshTask: Task<Void, Never>?

    private var lastNormalizedHome: StudentHomeData?

    private let refreshIntervalSeconds: UInt64 = 20

    init(service: HomeDashboardServiceProtocol, cache: HomeCacheStore, networkMonitor: NetworkMonitor) {
        self.service = service
        self.cache = cache
        self.networkMonitor = networkMonitor

        self.isOnline = networkMonitor.isOnline

        networkMonitor.$isOnline
            .removeDuplicates()
            .sink { [weak self] onlineNow in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = onlineNow
                if onlineNow && wasOffline {
                    Task { await self.refreshSilently() }
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    func onAppear() {
        loadInitial()
        startAutoRefresh()
    }

    private func normalizeForDiff(_ home: StudentHomeData) -> StudentHomeData {
        StudentHomeData(
            meta: HomeMeta(generatedAt: nil, apiVersion: home.meta.apiVersion),
            capabilities: home.capabilities,
            user: home.user,
            quickActions: home.quickActions,
            continueLearning: home.continueLearning,
            goals: home.goals,
            skeleton: home.skeleton
        )
    }

    private func loadInitial() {
        if let cached: CachedEnvelope<StudentHomeData> = cache.load(StudentHomeData.self, for: .studentHomeV1) {
            lastNormalizedHome = normalizeForDiff(cached.value)
            uiState = .content(home: cached.value, savedAt: cached.savedAt)
            Task { try? await Task.sleep(nanoseconds: 500_000_000); await refreshSilently() }
            return
        }

        uiState = .loading
        Task { await fetchAndPublish(showErrorsIfNoContent: true) }
    }

    private func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: refreshIntervalSeconds * 1_000_000_000)
                if Task.isCancelled { break }
                if self.isOnline {
                    await self.refreshSilently()
                }
            }
        }
    }

    func refreshSilently() async {
        await fetchAndPublish(showErrorsIfNoContent: false)
    }

    private func fetchAndPublish(showErrorsIfNoContent: Bool) async {
        do {
            let home = try await service.fetchStudentHome()
            try? cache.save(home, for: .studentHomeV1)

            let normalized = normalizeForDiff(home)
            if lastNormalizedHome != normalized {
                lastNormalizedHome = normalized
                uiState = .content(home: home, savedAt: Date())
            }
        } catch {
            let message = HomeErrorFormatter.message(for: error)

            switch uiState {
            case .content(let home, let savedAt):
                // Keep current UI stable; do not disrupt with errors.
                uiState = .content(home: home, savedAt: savedAt)
            case .loading, .error:
                if let cached: CachedEnvelope<StudentHomeData> = cache.load(StudentHomeData.self, for: .studentHomeV1) {
                    lastNormalizedHome = normalizeForDiff(cached.value)
                    uiState = .content(home: cached.value, savedAt: cached.savedAt)
                } else if showErrorsIfNoContent {
                    uiState = .error(message: message, cachedHome: nil, isOffline: !isOnline, cachedSavedAt: nil)
                }
            }
        }
    }
}
