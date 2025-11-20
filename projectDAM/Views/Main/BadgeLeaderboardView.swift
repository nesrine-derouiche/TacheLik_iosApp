import SwiftUI

struct BadgeLeaderboardView: View {
    @StateObject private var viewModel: BadgeLeaderboardViewModel
    
    init(badgeService: BadgeServiceProtocol = DIContainer.shared.badgeService) {
        _viewModel = StateObject(wrappedValue: BadgeLeaderboardViewModel(badgeService: badgeService))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            content
        }
        .navigationTitle("Badge Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInitial()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            ProgressView()
        } else if let error = viewModel.errorMessage, viewModel.entries.isEmpty {
            VStack(spacing: 8) {
                Text("Unable to load leaderboard")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        } else if viewModel.entries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "rosette")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No users with badges yet")
                    .font(.headline)
                Text("Earn badges by scoring high on quizzes to appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(24)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink(destination: UserBadgesView(userId: entry.id, username: entry.username)) {
                            leaderboardRow(rank: index + 1, entry: entry)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentEntry: entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }
    
    private func leaderboardRow(rank: Int, entry: BadgeLeaderboardEntry) -> some View {
        HStack(spacing: 14) {
            rankBadge(rank: rank)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.username)
                    .font(.system(size: 16, weight: .semibold))
                Text("\(entry.badgeCount) badge\(entry.badgeCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
    
    private func rankBadge(rank: Int) -> some View {
        let color: Color
        switch rank {
        case 1: color = Color.yellow
        case 2: color = Color.gray
        case 3: color = Color.orange
        default: color = Color.brandPrimary.opacity(0.9)
        }
        
        return ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
    }
}
