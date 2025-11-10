//
//  AdminUsersView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct AdminUsersView: View {
    @State private var searchText = ""
    @State private var selectedUserType = 0
    @State private var showUserMenu: String?
    
    enum UserType: Int, CaseIterable {
        case students, mentors, admins
        
        var label: String {
            switch self {
            case .students: return "Students"
            case .mentors: return "Mentors"
            case .admins: return "Admins"
            }
        }
        
        var icon: String {
            switch self {
            case .students: return "person.fill"
            case .mentors: return "person.badge.fill"
            case .admins: return "shield.fill"
            }
        }
        
        var count: Int {
            switch self {
            case .students: return 5
            case .mentors: return 4
            case .admins: return 2
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBarView()
                    
                    // User Type Tabs
                    userTypeTabsView()
                    
                    // Users List
                    usersList()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Users Management")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Search Bar
    private func searchBarView() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground).opacity(0.5))
                .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
        )
        .padding(DS.paddingMD)
    }
    
    // MARK: - User Type Tabs
    private func userTypeTabsView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(UserType.allCases, id: \.self) { type in
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 12, weight: .semibold))
                            
                            Text(type.label)
                                .font(.system(size: 13, weight: .semibold))
                            
                            ZStack {
                                Circle()
                                    .fill(Color.brandPrimary.opacity(0.15))
                                
                                Text("\(type.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.brandPrimary)
                            }
                            .frame(width: 20, height: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(selectedUserType == type.rawValue ? .brandPrimary : .secondary)
                        
                        if selectedUserType == type.rawValue {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.brandPrimary)
                                .frame(height: 3)
                        } else {
                            Color.clear.frame(height: 3)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedUserType = type.rawValue
                        }
                    }
                }
            }
            .padding(.horizontal, DS.paddingMD)
            
            Divider()
                .padding(.top, 0)
        }
    }
    
    // MARK: - Users List
    @ViewBuilder
    private func usersList() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                switch selectedUserType {
                case 0:
                    studentsListContent()
                case 1:
                    mentorsListContent()
                case 2:
                    adminsListContent()
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, DS.paddingMD)
        }
    }
    
    // MARK: - Students List
    private func studentsListContent() -> some View {
        VStack(spacing: 12) {
            UserListItemView(
                initials: "ABA",
                name: "Ahmed Ben Ali",
                email: "ahmed.benali@esprit.tn",
                coursesCount: 5,
                status: .active,
                statusLabel: "active"
            )
            
            UserListItemView(
                initials: "SM",
                name: "Sarra Mansour",
                email: "sarra.mansour@esprit.tn",
                coursesCount: 4,
                status: .active,
                statusLabel: "active"
            )
            
            UserListItemView(
                initials: "YT",
                name: "Youssef Trabelsi",
                email: "youssef.trabelsi@esprit.tn",
                coursesCount: 6,
                status: .active,
                statusLabel: "active"
            )
            
            UserListItemView(
                initials: "LR",
                name: "Leila Rezgui",
                email: "leila.rezgui@esprit.tn",
                coursesCount: 3,
                status: .inactive,
                statusLabel: "inactive"
            )
            
            UserListItemView(
                initials: "KH",
                name: "Karim Hassine",
                email: "karim.hassine@esprit.tn",
                coursesCount: 2,
                status: .active,
                statusLabel: "active"
            )
        }
    }
    
    // MARK: - Mentors List
    private func mentorsListContent() -> some View {
        VStack(spacing: 12) {
            UserListItemView(
                initials: "DS",
                name: "Dr. Sami Rezgui",
                email: "sami.rezgui@esprit.tn",
                coursesCount: 3,
                status: .active,
                statusLabel: "active",
                isMentor: true
            )
            
            UserListItemView(
                initials: "PL",
                name: "Prof. Leila Ben Amor",
                email: "leila.benamor@esprit.tn",
                coursesCount: 2,
                status: .active,
                statusLabel: "active",
                isMentor: true
            )
            
            UserListItemView(
                initials: "DH",
                name: "Dr. Hichem Ben Said",
                email: "hichem.bensaid@esprit.tn",
                coursesCount: 4,
                status: .active,
                statusLabel: "active",
                isMentor: true
            )
            
            UserListItemView(
                initials: "MT",
                name: "Dr. Mohamed Trabelsi",
                email: "mohamed.trabelsi@esprit.tn",
                coursesCount: 1,
                status: .inactive,
                statusLabel: "inactive",
                isMentor: true
            )
        }
    }
    
    // MARK: - Admins List
    private func adminsListContent() -> some View {
        VStack(spacing: 12) {
            UserListItemView(
                initials: "AF",
                name: "Admin Feki",
                email: "admin.feki@esprit.tn",
                coursesCount: nil,
                status: .active,
                statusLabel: "active",
                isAdmin: true
            )
            
            UserListItemView(
                initials: "SA",
                name: "Super Admin",
                email: "superadmin@esprit.tn",
                coursesCount: nil,
                status: .active,
                statusLabel: "active",
                isAdmin: true
            )
        }
    }
}

// MARK: - User List Item Component
private struct UserListItemView: View {
    enum UserStatus {
        case active, inactive
        
        var color: Color {
            switch self {
            case .active: return Color.brandSuccess
            case .inactive: return Color.secondary
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .inactive: return "xmark.circle.fill"
            }
        }
    }
    
    let initials: String
    let name: String
    let email: String
    let coursesCount: Int?
    let status: UserStatus
    let statusLabel: String
    let isMentor: Bool
    let isAdmin: Bool
    
    @State private var showMenu = false
    
    init(
        initials: String,
        name: String,
        email: String,
        coursesCount: Int? = nil,
        status: UserStatus = .active,
        statusLabel: String = "",
        isMentor: Bool = false,
        isAdmin: Bool = false
    ) {
        self.initials = initials
        self.name = name
        self.email = email
        self.coursesCount = coursesCount
        self.status = status
        self.statusLabel = statusLabel
        self.isMentor = isMentor
        self.isAdmin = isAdmin
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.3),
                                    Color.brandAccent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
                .frame(width: 48, height: 48)
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if isMentor {
                            Text("mentor")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandPrimary.opacity(0.7))
                                .cornerRadius(4)
                        }
                        
                        if isAdmin {
                            Text("admin")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandError.opacity(0.7))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(email)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status & Menu
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        if let count = coursesCount {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("\(count) courses")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: status.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(statusLabel)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(status.color)
                    }
                    
                    Button(action: { showMenu.toggle() }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            
            // Context Menu
            if showMenu {
                VStack(spacing: 8) {
                    MenuButton(
                        icon: "eye.fill",
                        label: "View Profile",
                        color: .brandPrimary
                    )
                    
                    MenuButton(
                        icon: "pencil.circle.fill",
                        label: "Edit User",
                        color: .brandAccent
                    )
                    
                    MenuButton(
                        icon: "xmark.circle.fill",
                        label: "Deactivate",
                        color: .brandError
                    )
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DS.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground))
                .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Menu Button Component
private struct MenuButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(6)
        }
    }
}

#Preview {
    AdminUsersView()
}
