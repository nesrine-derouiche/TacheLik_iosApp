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

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                NavigationView {
                    LoginView()
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}
