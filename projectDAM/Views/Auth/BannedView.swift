//
//  BannedView.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import SwiftUI

struct BannedView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Ban icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "hand.raised.slash.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.red)
                }
                
                VStack(spacing: 12) {
                    Text("Account Suspended")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your account has been suspended")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    Text("If you believe this is a mistake, please contact our support team.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Contact Support Button
                    Button(action: {
                        // Open email or support page
                        if let url = URL(string: "mailto:support@tachelik.tn") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Contact Support")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    // Logout Button
                    Button(action: {
                        sessionManager.logout()
                        isLoggedIn = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Logout")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    BannedView(
        sessionManager: .init()
    )
}
