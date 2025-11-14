import SwiftUI

struct WalletView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @State private var friendInviteCode: String = ""
    @State private var showReferralSheet: Bool = false
    
    private var currentUser: User? {
        authService.currentUser
    }

struct ReferralDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var friendInviteCode: String
    let inviteLink: String
    let isAlreadyInvited: Bool
    let invitedByCode: String?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    referralStatsGrid
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if isAlreadyInvited {
                            Text("You’re already linked to a friend, so entering another code isn’t needed.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let code = invitedByCode {
                                HStack {
                                    Text("Linked code: \(code)")
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                        } else {
                            Text("Enter a friend code if you were invited")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("Friend code", text: $friendInviteCode)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Invite Link")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            Text(inviteLink)
                                .font(.callout)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.brandPrimary)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    Button {
                        // Invite friends action placeholder
                    } label: {
                        Text("Invite Friends")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(20)
                    }
                    .padding(.top, 4)
                    
                    Text("Earn 2 points for every friend who makes a purchase!")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, DS.barHeight + 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Friend Invites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var referralStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            referralStatCard(title: "Friends Joined", value: "0")
            referralStatCard(title: "Active Friends", value: "0")
            referralStatCard(title: "Points Earned", value: "0")
            referralStatCard(title: "Points per Join", value: "1")
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private func referralStatCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.brandPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
    
    private var tCreditsBalanceText: String {
        if let credit = currentUser?.credit {
            return "\(credit)"
        }
        return "0"
    }
    
    private var invitedByCode: String? {
        guard let code = currentUser?.invitedBy?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else { return nil }
        return code
    }
    
    private var hasExistingInvite: Bool {
        invitedByCode != nil
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let maxContentWidth: CGFloat = 640
                let horizontalPadding = max((geometry.size.width - maxContentWidth) / 2, 20)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        balanceSection
                        accountsSection
                        rechargeSection
                        referralsSection
                        historySection
                        tutorialsSection
                    }
                    .frame(maxWidth: maxContentWidth)
                    .padding(.vertical, 24)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, DS.barHeight + 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showReferralSheet) {
            ReferralDetailSheet(
                friendInviteCode: $friendInviteCode,
                inviteLink: currentUser?.inviteLink ?? "No link available",
                isAlreadyInvited: hasExistingInvite,
                invitedByCode: invitedByCode
            )
        }
    }
    
    // MARK: - Sections
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Balance")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tCreditsBalanceText)
                        .font(.system(size: 34, weight: .bold))
                    Text("T-Credits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image("T-Credits")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Company Accounts")
                .font(.headline)
            
            VStack(spacing: 12) {
                accountRow(title: "D17 Account 1", value: "--------")
                accountRow(title: "D17 Account 2", value: "--------")
                accountRow(title: "Bank Account 1", value: "--------")
                accountRow(title: "Bank Account 2", value: "--------")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
    
    private func accountRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(value)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "doc.on.doc")
                .foregroundColor(.brandPrimary)
        }
    }
    
    private var rechargeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recharge T-Credits")
                .font(.headline)
            
            HStack(spacing: 12) {
                rechargeMethodCard(image: "D17", title: "D17")
                rechargeMethodCard(image: "cash_payment", title: "cash_payment")
                rechargeMethodCard(image: "gift_card", title: "gift_card")
            }
        }
    }
    
    private func rechargeMethodCard(image: String, title: String) -> some View {
        VStack(spacing: 10) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 44)
            Text(title.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
    
    private var referralsSection: some View {
        Button {
            showReferralSheet = true
        } label: {
            HStack(spacing: 16) {
                Image("invite_friends")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Friend Invites")
                        .font(.headline)
                    Text(hasExistingInvite ? "Friend link already active." : "Earn rewards when friends join Tache-lik.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        summaryPill(title: "Friends", value: "0")
                        summaryPill(title: "Points", value: "0")
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.brandPrimary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction History")
                .font(.headline)
            
            VStack(spacing: 12) {
                historyRow(title: "Course Purchase", amount: "-20 T-Credits", date: "Nov 1, 2025")
                historyRow(title: "Referral Bonus", amount: "+10 T-Credits", date: "Oct 21, 2025")
                historyRow(title: "Wallet Recharge", amount: "+50 T-Credits", date: "Oct 10, 2025")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
    
    private func historyRow(title: String, amount: String, date: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(amount)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(amount.hasPrefix("-") ? .red : .green)
        }
    }
    
    private var tutorialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tutorial Videos")
                .font(.headline)
            
            VStack(spacing: 12) {
                tutorialRow(title: "How T-Credits Work")
                tutorialRow(title: "How to Recharge via D17")
                tutorialRow(title: "How to Use Gift Cards")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
    
    private func tutorialRow(title: String) -> some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.brandPrimary)
            Text(title)
                .font(.subheadline)
            Spacer()
        }
    }
}
