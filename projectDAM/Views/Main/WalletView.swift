import SwiftUI

struct WalletView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @StateObject private var walletViewModel = DIContainer.shared.makeWalletViewModel()
    @State private var friendInviteCode: String = ""
    @State private var showReferralSheet = false
    @State private var showAllTransactions = false
    @State private var showD17Sheet = false
    @State private var showCashSheet = false
    @State private var showGiftCardSheet = false
    private let transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
    
    private var currentUserId: String? {
        currentUser?.id
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
        .sheet(isPresented: $showD17Sheet) {
            D17PaymentSheet()
        }
        .sheet(isPresented: $showCashSheet) {
            CashPaymentSheet()
        }
        .sheet(isPresented: $showGiftCardSheet) {
            GiftCardSheet()
        }
        .task(id: currentUserId) {
            guard let userId = currentUserId else { return }
            await walletViewModel.loadInitialTransactions(for: userId)
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
                accountRow(title: "Amen Bank - ABIDI MOHAMED", value: "07 116 0163105509356 39")
                accountRow(title: "Attijari Bank - OUSSEMA ISSAOUI", value: "04 034 1200080184930 40")
                accountRow(title: "D17 - Tache-lik", value: "93 213 636")
                accountRow(title: "D17 - Tache-lik", value: "26 396 236")
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
                    .fontWeight(.medium)
                Text(value)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.brandPrimary)
            }
        }
    }
    
    private var rechargeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recharge T-Credits")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button { showD17Sheet = true } label: {
                    rechargeMethodCard(image: "D17", title: "D17")
                }
                Button { showCashSheet = true } label: {
                    rechargeMethodCard(image: "cash_payment", title: "Cash Payment")
                }
                Button { showGiftCardSheet = true } label: {
                    rechargeMethodCard(image: "gift_card", title: "Gift Card")
                }
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
            HStack {
                Text("Transaction History")
                    .font(.headline)
                Spacer()
                if walletViewModel.isInitialLoading {
                    ProgressView()
                }
            }
            
            Group {
                if walletViewModel.isInitialLoading {
                    historySkeleton
                } else if let error = walletViewModel.errorMessage {
                    historyErrorState(message: error)
                } else if walletViewModel.transactions.isEmpty {
                    historyEmptyState
                } else {
                    transactionList
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
    
    private var historySkeleton: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 46)
            }
        }
    }
    
    private var historyEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("No transactions yet")
                .font(.subheadline.weight(.semibold))
            Text("Your future payments, rewards, and purchases will show up here.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private func historyErrorState(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Couldn't load transactions")
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if let userId = currentUserId {
                Button {
                    Task { await walletViewModel.refreshTransactions(for: userId) }
                } label: {
                    Text("Retry")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.brandPrimary.opacity(0.15)))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    private var transactionList: some View {
        VStack(spacing: 12) {
            let displayedTransactions = showAllTransactions ? walletViewModel.transactions : Array(walletViewModel.transactions.prefix(3))
            
            ForEach(displayedTransactions) { transaction in
                transactionRow(transaction)
            }
            
            if !showAllTransactions && walletViewModel.transactions.count > 3 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllTransactions = true
                    }
                } label: {
                    Text("Show More (\(walletViewModel.transactions.count - 3) more)")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brandPrimary.opacity(0.1)))
                }
            }
            
            if showAllTransactions {
                if walletViewModel.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if walletViewModel.hasMorePages {
                    Button {
                        Task { await walletViewModel.loadNextPage() }
                    } label: {
                        Text("Load More")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.brandPrimary.opacity(0.1)))
                    }
                    .disabled(walletViewModel.isLoadingMore)
                }
            }
        }
    }
    
    private func transactionRow(_ transaction: PaymentTransaction) -> some View {
        let formatted = formattedAmount(for: transaction)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(formattedDate(for: transaction))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatted.text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(formatted.color)
        }
        .padding(.vertical, 4)
    }

    private func formattedAmount(for transaction: PaymentTransaction) -> (text: String, color: Color) {
        let rawAmount = Double(transaction.amount) ?? 0
        let isDebit: Bool
        if rawAmount != 0 {
            isDebit = rawAmount < 0
        } else {
            isDebit = transaction.type.contains("buy") || transaction.type.contains("withdraw")
        }
        let absoluteValue = abs(rawAmount)
        let amountString: String
        if absoluteValue == 0 {
            amountString = "0.00"
        } else {
            amountString = String(format: "%.2f", absoluteValue)
        }
        let prefix = isDebit ? "-" : "+"
        let color: Color = isDebit ? .red : .brandSuccess
        return ("\(prefix)\(amountString) T-Credits", color)
    }
    
    private func formattedDate(for transaction: PaymentTransaction) -> String {
        transactionDateFormatter.string(from: transaction.date)
    }
    
    private var tutorialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tutorial Videos")
                .font(.headline)
            
            VStack(spacing: 12) {
                tutorialRow(title: "How to pay with D17", videoId: "IIYaIZzD0EM")
                tutorialRow(title: "How to pay with Cash", videoId: "xiVpbl6HpOI")
                tutorialRow(title: "How to pay with Gift Card", videoId: "HQjmhTtyWNI")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
    
    private func tutorialRow(title: String, videoId: String) -> some View {
        Button {
            if let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.brandPrimary)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Payment Method Sheets
struct D17PaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAccount = "93 213 636"
    @State private var amount = ""
    @State private var authNumber = ""
    @State private var senderPhone = ""
    @State private var showImagePicker = false
    
    private let d17Accounts = ["93 213 636", "26 396 236"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image("D17")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            Text("D17 Payment")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        Text("Send money to one of these numbers:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Account Selection
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(d17Accounts, id: \.self) { account in
                            Button {
                                selectedAccount = account
                            } label: {
                                HStack {
                                    Text(account)
                                        .font(.title3.weight(.medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedAccount == account {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedAccount == account ? Color.brandPrimary : Color(.systemGray4), lineWidth: 2)
                                )
                            }
                        }
                    }
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: 16) {
                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.headline)
                            TextField("Enter amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("0/4 digits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Authorization Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Authorization number")
                                .font(.headline)
                            HStack {
                                TextField("Enter authorization number", text: $authNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button {
                                    showImagePicker = true
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.brandPrimary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Sender's Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sender's phone")
                                .font(.headline)
                            TextField("Enter phone number", text: $senderPhone)
                                .keyboardType(.phonePad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("0/8 digits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Submit Button
                    Button {
                        // Handle submission
                        dismiss()
                    } label: {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(amount.isEmpty || authNumber.isEmpty || senderPhone.isEmpty)
                }
                .padding()
            }
            .navigationTitle("D17 Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct CashPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cashAmount = ""
    @State private var senderPhone = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image("cash_payment")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            Text("Cash Payment")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        Text("Submit your cash payment details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: 16) {
                        // Cash Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cash Amount")
                                .font(.headline)
                            TextField("Enter amount", text: $cashAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("0/4 digits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Sender's Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sender's phone")
                                .font(.headline)
                            TextField("Enter phone number", text: $senderPhone)
                                .keyboardType(.phonePad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("0/8 digits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Submit Button
                    Button {
                        // Handle submission
                        dismiss()
                    } label: {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(cashAmount.isEmpty || senderPhone.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Cash Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct GiftCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var giftCardCode = ["", "", "", ""]
    @FocusState private var focusedField: Int?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image("gift_card")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            Text("Gift Card")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        Text("Enter your gift card code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Gift Card Code Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gift Card Code")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { index in
                                TextField("", text: $giftCardCode[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                    .font(.title2.weight(.medium))
                                    .frame(height: 60)
                                    .focused($focusedField, equals: index)
                                    .onChange(of: giftCardCode[index]) { newValue in
                                        if newValue.count > 4 {
                                            giftCardCode[index] = String(newValue.prefix(4))
                                        }
                                        if newValue.count == 4 && index < 3 {
                                            focusedField = index + 1
                                        }
                                    }
                            }
                        }
                        
                        Text("0/16 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Redeem Button
                    Button {
                        // Handle redemption
                        dismiss()
                    } label: {
                        Text("Redeem")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(giftCardCode.allSatisfy { $0.count == 4 } == false)
                }
                .padding()
            }
            .navigationTitle("Gift Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            focusedField = 0
        }
    }
}
