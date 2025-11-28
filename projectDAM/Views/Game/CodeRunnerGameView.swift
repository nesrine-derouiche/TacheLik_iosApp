import SwiftUI
import SpriteKit
import Combine

struct CodeRunnerGameView: View {
    @State private var gameId = UUID()
    
    var body: some View {
        CodeRunnerGameContent(gameId: gameId) {
            // Restart Action: Change ID to force re-creation
            gameId = UUID()
        }
        .id(gameId) // This forces the view (and its StateObject) to be destroyed and recreated
    }
}

private struct CodeRunnerGameContent: View {
    let gameId: UUID
    let onRestart: () -> Void
    
    @StateObject private var gameState = GameState()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameState.scene, isPaused: gameState.isPaused)
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                HStack {
                    Text("Score: \(gameState.score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
                .padding(.top, 50) // Adjust for safe area
                .padding(.horizontal)
                
                // Question Display
                VStack(spacing: 12) {
                    Text(gameState.currentQuestion)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(16)
                        .shadow(radius: 4)
                    
                    if !gameState.currentOptions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(0..<gameState.currentOptions.count, id: \.self) { index in
                                Text(gameState.currentOptions[index])
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .onAppear {
                gameState.setup()
            }
            
            if gameState.isGameOver {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("GAME OVER")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.5), radius: 10)
                        
                        VStack(spacing: 8) {
                            Text("Final Score")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(gameState.score)")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 16) {
                            Button {
                                onRestart()
                            } label: {
                                Text("Play Again")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.brandPrimary)
                                    .cornerRadius(16)
                            }
                            
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Exit")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(hex: "1A1A1A"))
                            .shadow(radius: 20)
                    )
                    .padding(20)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }
}

class GameState: ObservableObject, CodeRunnerGameDelegate {
    @Published var score = 0
    @Published var isGameOver = false
    @Published var isPaused = false
    @Published var currentQuestion = "Get Ready..."
    @Published var currentOptions: [String] = []
    @Published var scene: CodeRunnerScene
    
    init() {
        let s = CodeRunnerScene()
        s.scaleMode = .resizeFill
        self.scene = s
    }
    
    func setup() {
        scene.gameDelegate = self
    }
    
    func gameDidEnd(score: Int) {
        DispatchQueue.main.async {
            withAnimation {
                self.isGameOver = true
                self.isPaused = true
            }
        }
    }
    
    func scoreDidUpdate(score: Int) {
        DispatchQueue.main.async {
            self.score = score
        }
    }
    
    func didSpawnQuestion(_ question: GameQuestion) {
        DispatchQueue.main.async {
            withAnimation {
                self.currentQuestion = question.questionText
                self.currentOptions = question.options
            }
        }
    }
    
    func restartGame() {
        let newScene = CodeRunnerScene()
        newScene.scaleMode = .resizeFill
        newScene.gameDelegate = self
        
        DispatchQueue.main.async {
            self.scene = newScene
            self.score = 0
            self.currentQuestion = "Get Ready..."
            self.currentOptions = []
            self.isPaused = false
            withAnimation {
                self.isGameOver = false
            }
        }
    }
}
