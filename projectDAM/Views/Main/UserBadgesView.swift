import SwiftUI

struct UserBadgesView: View {
    @StateObject private var viewModel: UserBadgesViewModel

    init(userId: String, username: String, badgeService: BadgeServiceProtocol = DIContainer.shared.badgeService) {
        _viewModel = StateObject(wrappedValue: UserBadgesViewModel(userId: userId, username: username, badgeService: badgeService))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            content
        }
        .navigationTitle(viewModel.username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBadges()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.badges.isEmpty {
            ProgressView()
        } else if let error = viewModel.errorMessage, viewModel.badges.isEmpty {
            VStack(spacing: 8) {
                Text("Unable to load badges")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        } else if viewModel.badges.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "rosette")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No badges yet")
                    .font(.headline)
                Text("This user has not earned any badges yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(24)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(viewModel.badges, id: \.id) { awarded in
                        badgeCard(for: awarded)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }

    private func badgeCard(for awarded: AwardedBadge) -> some View {
        let badge = awarded.badge
        return HStack(spacing: 16) {
            badgeIconView(badge)

            VStack(alignment: .leading, spacing: 6) {
                Text(badge.name)
                    .font(.system(size: 17, weight: .semibold))
                if let description = badge.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                Text(formattedDate(awarded.awardedAt))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    private func badgeIconView(_ badge: Badge) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let urlString = badge.iconUrl, let url = URL(string: urlString) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(2)
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .failure:
                        Image(systemName: "rosette")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    @unknown default:
                        Image(systemName: "rosette")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Image(systemName: "rosette")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 80, height: 80)
    }

    private func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return "" }
        let display = DateFormatter()
        display.dateStyle = .medium
        return "Awarded on " + display.string(from: date)
    }
}
