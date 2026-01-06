//
//  projectDAMApp.swift
//  projectDAM
//
//  Created by nesrine derouiche on 07/11/2025.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - AppDelegate for Portrait Lock
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Force portrait orientation for the entire app
        return .portrait
    }
}

@main
struct projectDAMApp: App {
    // Use AppDelegate for orientation control
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var sessionManager = SessionManager()
    @State private var showSplash = true
    
    init() {
        // Print configuration on app launch (debug only)
        AppConfig.printConfiguration()

        // Ensure navigation chrome stays readable in dark mode (avoid pure black bars).
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appNavBarBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(isLoggedIn: $isLoggedIn, sessionManager: sessionManager)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .animation(.easeInOut(duration: 0.2), value: isDarkMode)
                    .environmentObject(sessionManager)
                    .environmentObject(DIContainer.shared.roleManager)
                
                if showSplash {
                    SplashView(onSplashComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSplash = false
                        }
                    })
                        .transition(.opacity)
                }
            }
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
    
    @ObservedObject private var authService = DIContainer.shared.observableAuthService
    @EnvironmentObject var roleManager: RoleManager
    
    private var currentUser: User? {
        authService.currentUser
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
                                // Update role manager when user data is available
                                roleManager.updateRole(from: user)
                                // Auto-reconnect socket if user is logged in
                                sessionManager.reconnectIfNeeded()
                            }
                            .onChange(of: currentUser) { newUser in
                                // Update role if user data changes
                                if let newUser = newUser {
                                    roleManager.updateRole(from: newUser)
                                }
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
                roleManager.updateRole(from: User(
                    id: "", username: "", email: "", phone: nil, phoneNbVerified: nil,
                    role: .student, creationDate: nil, image: nil, verified: nil,
                    banned: nil, credit: nil, isTeacher: nil, inviteLink: nil,
                    invitedBy: nil, inviteLinkType: nil, haveReduction: nil,
                    warningTimes: nil, lastLoginDate: nil
                )) // Reset role on logout
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
                
                // Update role manager when user data is fetched
                if let user = authService.getCurrentUser() {
                    roleManager.updateRole(from: user)
                }
                
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
