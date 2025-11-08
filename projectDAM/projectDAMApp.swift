//
//  projectDAMApp.swift
//  projectDAM
//
//  Created by nesrine derouiche on 07/11/2025.
//

import SwiftUI
import CoreData

@main
struct projectDAMApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var sessionManager = SessionManager()
    
    init() {
        // Print configuration on app launch (debug only)
        AppConfig.printConfiguration()
    }

    var body: some Scene {
        WindowGroup {
            RootView(isLoggedIn: $isLoggedIn, sessionManager: sessionManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environmentObject(sessionManager)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isLoadingUser = false
    
    private let authService = DIContainer.shared.authService
    
    private var currentUser: User? {
        authService.getCurrentUser()
    }
    
    var body: some View {
        Group {
            if isLoggedIn && !sessionManager.isSessionTerminated {
                // Check user status
                if let user = currentUser {
                    if user.banned == true {
                        // User is banned - show ban screen
                        BannedView()
                    } else if user.verified == false {
                        // User is not verified - show verification screen
                        VerificationView()
                    } else {
                        // User is verified and not banned - show main app
                        MainTabView()
                            .onAppear {
                                // Auto-reconnect socket if user is logged in
                                sessionManager.reconnectIfNeeded()
                            }
                    }
                } else if isLoadingUser {
                    // Loading user data
                    LoadingView()
                } else {
                    // No user data and not loading - fetch it
                    Color.clear
                        .onAppear {
                            loadUserData()
                        }
                }
            } else {
                NavigationView {
                    LoginView()
                }
            }
        }
        .alert("Session Terminated", isPresented: $sessionManager.showSessionAlert) {
            Button("OK") {
                sessionManager.handleSessionTermination()
                isLoggedIn = false
            }
        } message: {
            Text(sessionManager.sessionTerminationReason)
        }
        .onAppear {
            // Setup notification observer when view appears
            NotificationCenter.default.addObserver(
                forName: .socketSessionTerminated,
                object: nil,
                queue: .main
            ) { notification in
                if let reason = notification.userInfo?["reason"] as? String {
                    print("📱 Received session termination notification: \(reason)")
                    sessionManager.terminateSession(reason: reason)
                }
            }
        }
    }
    
    private func loadUserData() {
        guard authService.shouldAutoLogin() else {
            isLoggedIn = false
            return
        }
        
        isLoadingUser = true
        
        Task {
            do {
                try await authService.refreshUserData()
                isLoadingUser = false
                
                // Reconnect socket after user data is loaded
                sessionManager.reconnectIfNeeded()
            } catch {
                print("❌ Failed to load user data: \(error.localizedDescription)")
                isLoadingUser = false
                isLoggedIn = false
            }
        }
    }
}
