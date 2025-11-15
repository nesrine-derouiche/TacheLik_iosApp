import SwiftUI

struct HomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @State private var isShowingWalletAlert = false
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var userCredits: Int {
        currentUser?.credit ?? 0
    }
    
    private var userInitials: String {
        guard let username = currentUser?.username else { return "U" }
        let components = username.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(username.prefix(2)).uppercased()
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                    // Welcome Header
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let user = currentUser {
                                Text(user.username)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .primary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                // Role badge
                                HStack(spacing: 6) {
                                    Image(systemName: user.isTeacher == true ? "person.fill.badge.plus" : "person.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(user.role.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.brandPrimary.opacity(0.1))
                                .cornerRadius(12)
                            } else {
                                Text("Continue Learning")
                                    .font(.system(size: 28, weight: .bold))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Statistics Cards
                    HStack(spacing: 16) {
                        StatCardHome(
                            icon: "book.fill",
                            value: "8",
                            label: "Courses",
                            color: Color.brandPrimary
                        )
                        
                        StatCardHome(
                            icon: "clock.fill",
                            value: "124h",
                            label: "Hours",
                            color: Color.brandAccent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Learning Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Continue Learning")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)
                        
                        BeautifulCourseCard(
                            title: "Advanced Web Development",
                            instructor: "Dr. Sami Rezgui",
                            progress: 0.92,
                            timeLeft: "45 min",
                            lessonsCompleted: 13,
                            totalLessons: 20,
                            color: Color.brandPrimary
                        )
                        .padding(.horizontal, 20)
                        
                        BeautifulCourseCard(
                            title: "Data Structures & Algorithms",
                            instructor: "Prof. Leila Ben Amor",
                            progress: 0.42,
                            timeLeft: "1h 20min",
                            lessonsCompleted: 7,
                            totalLessons: 15,
                            color: Color.purple
                        )
                        .padding(.horizontal, 20)
                    }
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, DS.barHeight + 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    UnifiedTopAppBarLogoView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    UnifiedTopAppBarActions(
                        userCredits: userCredits,
                        isShowingWalletAlert: $isShowingWalletAlert
                    )
                }
            }
            .alert("Wallet", isPresented: $isShowingWalletAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Wallet Screen will be developed soon.")
            }
        }
    }
}

struct TCreditsWalletChip: View {
    let credits: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Image("T-Credits")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                )
                .shadow(color: Color.brandPrimary.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 4, x: 0, y: 2)
            
            Text("\(credits)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
                .padding(.trailing, 2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

struct StatCardHome: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct BeautifulCourseCard: View {
    let title: String
    let instructor: String
    let progress: Double
    let timeLeft: String
    let lessonsCompleted: Int
    let totalLessons: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Course Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(2)
                    Text(instructor)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(color)
                        Text("\(lessonsCompleted)/\(totalLessons) lessons")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(timeLeft)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Continue Button
            Button(action: {}) {
                HStack {
                    Text("Continue Learning")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}
