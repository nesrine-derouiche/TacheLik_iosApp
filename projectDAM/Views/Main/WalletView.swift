import SwiftUI

struct WalletView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var tCreditsBalanceText: String {
        if let credit = currentUser?.credit {
            return "\(credit)"
        }
        return "0"
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    balanceSection
                    accountsSection
                    rechargeSection
                    referralsSection
                    historySection
                    tutorialsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
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
                ZStack {
                    Circle()
                        .fill(LinearGradient.brandPrimaryGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
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
                rechargeMethodCard(icon: "banknote.fill", title: "Cash")
                rechargeMethodCard(icon: "phone.fill", title: "D17")
                rechargeMethodCard(icon: "gift.fill", title: "Gift Card")
            }
        }
    }
    
    private func rechargeMethodCard(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.brandPrimary)
            }
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
    
    private var referralsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friend Invites")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                let inviteCode = currentUser?.inviteLink ?? ""
                Text("Share your referral link with friends and earn T-Credits when they join.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !inviteCode.isEmpty {
                    HStack {
                        Text(inviteCode)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.brandPrimary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
                
                Button {
                    // Invite action placeholder
                } label: {
                    Text("Invite Friends")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .cornerRadius(16)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
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
