import SwiftUI
import SpriteKit
import Combine

struct CodeRunnerGameView: View {
    @State private var gameId = UUID()
    @State private var isLoading = true
    @State private var loadingError: String?
    let courseId: String
    
    var body: some View {
        ZStack {
            if isLoading {
                GameLoadingView()
            } else if let error = loadingError {
                GameErrorView(error: error) {
                    // Retry
                    isLoading = true
                    loadingError = nil
                    Task {
                        await loadQuestions()
                    }
                }
            } else {
                CodeRunnerGameContent(gameId: gameId, courseId: courseId) {
                    // Restart Action: Change ID to force re-creation
                    gameId = UUID()
                }
                .id(gameId)
            }
        }
        .onAppear {
            Task {
                await loadQuestions()
            }
        }
    }
    
    private func loadQuestions() async {
        do {
            GameQuestionProvider.shared.reset()
            try await GameQuestionProvider.shared.loadQuestionsFromCourse(courseId: courseId)
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadingError = error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct GameLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Loading Questions...")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Generating game questions from course content")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

private struct GameErrorView: View {
    let error: String
    let onRetry: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Failed to Load Questions")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 16) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                    
                    Button {
                        onRetry()
                    } label: {
                        Text("Retry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

private struct CodeRunnerGameContent: View {
    let gameId: UUID
    let courseId: String
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
}
