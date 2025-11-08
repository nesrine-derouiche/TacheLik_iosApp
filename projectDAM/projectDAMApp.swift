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
    
    var body: some View {
        Group {
            if isLoggedIn && !sessionManager.isSessionTerminated {
                MainTabView()
                    .onAppear {
                        // Auto-reconnect socket if user is logged in
                        sessionManager.reconnectIfNeeded()
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
}
