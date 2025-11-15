//
//  SplashView.swift
//  projectDAM
//
//  Created on 11/12/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 4.0
    @State private var logoOpacity: Double = 0.7
    @State private var logoRotation: Double = -45.0
    @State private var logoOffsetY: CGFloat = -UIScreen.main.bounds.height * 0.6
    @State private var textOpacity: Double = 0.0
    @State private var shouldDismiss = false
    
    var onSplashComplete: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background color (system background)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo Container
                VStack(spacing: 20) {
                    // Logo - Full icon centered
                    Image("tache_lik_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(-45))
                        .offset(y: logoOffsetY)
                        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                    
                    // Text - Tache-lik with proper styling
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("T")
                                .foregroundColor(Color(red: 0.867, green: 0.341, blue: 0.275)) // #DD5746
                                .font(.custom("Nunito-ExtraBold", size: 48))
                            
                            Text("ache-lik")
                                .foregroundColor(Color(red: 0.282, green: 0.576, blue: 0.686)) // #4793af
                                .font(.custom("Nunito-ExtraBold", size: 48))
                        }
                    }
                    .opacity(textOpacity)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Main animation: scale, translate, rotate, fade-in (800ms)
        withAnimation(.easeInOut(duration: 0.8)) {
            logoScale = 0.7
            logoOffsetY = 0
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Impact bounce animation (starts at 800ms, duration 240ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.12)) {
                logoScale = 0.65
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    logoScale = 0.7
                }
            }
        }
        
        // Text fade in (starts at 1120ms = 800 + 240 + 80, duration 420ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.12) {
            withAnimation(.easeInOut(duration: 0.42)) {
                textOpacity = 1.0
            }
        }
        
        // Trigger completion (after all animations + 1 second delay)
        // Total: 800 + 240 + 80 + 420 + 1000 = 2540ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.54) {
            onSplashComplete()
        }
    }
}

// Preview
#Preview {
    SplashView()
}
