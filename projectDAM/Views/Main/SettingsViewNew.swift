import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @EnvironmentObject var sessionManager: SessionManager
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                    // Profile Card
                    VStack(spacing: 20) {
                        ZStack {
                            if let imageUrl = currentUser?.image, !imageUrl.isEmpty {
                                // Display user image
                                if imageUrl.hasPrefix("data:image") {
                                    // Handle base64 data URL
                                    if let data = Data(base64Encoded: imageUrl.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                                    } else {
                                        placeholderAvatar
                                    }
                                } else {
                                    // Handle regular URL
                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 90, height: 90)
                                                .clipShape(Circle())
                                                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                                        case .failure, .empty:
                                            placeholderAvatar
                                        @unknown default:
                                            placeholderAvatar
                                        }
                                    }
                                }
                            } else {
                                placeholderAvatar
                            }
                        }
                        
                        VStack(spacing: 6) {
                            Text(currentUser?.username ?? "User")
                                .font(.system(size: 22, weight: .bold))
                            Text(currentUser?.email ?? "")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(currentUser?.role.rawValue ?? "Student")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.brandPrimary.opacity(0.15))
                                .cornerRadius(12)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 20)
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPEARANCE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "moon.fill",
                                title: "Dark Mode",
                                iconColor: .indigo,
                                toggle: $isDarkMode
                            )
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            if let user = currentUser {
                                NavigationLink {
                                    EditProfileView(
                                        viewModel: DIContainer.shared.makeEditProfileViewModel(user: user)
                                    )
                                } label: {
                                    SettingsRowNavigation(
                                        icon: "person.fill",
                                        title: "Personal Information",
                                        iconColor: .brandPrimary
                                    )
                                }
                            } else {
                                SettingsRowNavigation(
                                    icon: "person.fill",
                                    title: "Personal Information",
                                    iconColor: .brandPrimary
                                )
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            NavigationLink(destination: Text("Email Settings")) {
                                SettingsRowNavigation(
                                    icon: "envelope.fill",
                                    title: "Email Settings",
                                    iconColor: .green
                                )
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            NavigationLink(destination: ChangePasswordView()) {
                                SettingsRowNavigation(
                                    icon: "lock.fill",
                                    title: "Change Password",
                                    iconColor: .orange
                                )
                            }

                            Divider().padding(.leading, 56)

                            NavigationLink(destination: BadgesView()) {
                                SettingsRowNavigation(
                                    icon: "rosette",
                                    title: "My Badges",
                                    iconColor: .purple
                                )
                            }

                            Divider().padding(.leading, 56)

                            NavigationLink(destination: WalletView()) {
                                SettingsRowNavigation(
                                    icon: "creditcard.fill",
                                    title: "Wallet",
                                    iconColor: .brandSuccess
                                )
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            NavigationLink(destination: BookmarksView()) {
                                SettingsRowNavigation(
                                    icon: "bookmark.fill",
                                    title: "Saved Reels",
                                    iconColor: .yellow
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Logout Button
                    Button(action: {
                        sessionManager.logout()
                        isLoggedIn = false
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Logout")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, DS.barHeight + 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.brandPrimary,
                        Color.brandPrimary.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 90, height: 90)
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            .overlay(
                Text(currentUser?.username.prefix(3).uppercased() ?? "U")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    @Binding var toggle: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Toggle("", isOn: $toggle)
                .labelsHidden()
        }
        .padding(16)
    }
}

struct SettingsRowNavigation: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
}
