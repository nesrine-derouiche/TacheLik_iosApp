//
//  AIGameSelectionView.swift
//  projectDAM
//
//  View to select AI-generated game type
//

import SwiftUI

struct AIGameSelectionView: View {
    let courseId: String
    let courseName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGameType: AIGameType?
    @State private var selectedDifficulty: PuzzleDifficulty = .medium
    @State private var isLoading = false
    @State private var showGame = false
    @State private var isRandomizing = false
    @State private var randomizeTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Random Game Preview (shows cycling games)
                        randomGameSection
                        
                        // Difficulty Selection
                        difficultySection
                        
                        // Start Button
                        startButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("AI Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                if let gameType = selectedGameType {
                    switch gameType {
                    case .quiz:
                        // Quick quiz with AI questions
                        QuickQuizGameView(courseId: courseId)
                    case .puzzle:
                        PuzzleGameView(courseId: courseId, difficulty: selectedDifficulty)
                    case .codeRunner:
                        CodeRunnerGameView(courseId: courseId)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // AI Icon with rotation animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary, .brandPrimary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isRandomizing ? 360 : 0))
                    .animation(isRandomizing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRandomizing)
            }
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            
            Text("Random AI Game")
                .font(.system(size: 26, weight: .bold))
            
            Text("Press start and let AI pick a random game\nfrom \"\(courseName)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Random Game Section
    private var randomGameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Game Preview")
                .font(.system(size: 18, weight: .bold))
            
            // Show current game type (cycling during randomization)
            VStack(spacing: 12) {
                ForEach(AIGameType.allCases) { gameType in
                    GameTypeCard(
                        gameType: gameType,
                        isSelected: selectedGameType == gameType,
                        isRandomizing: isRandomizing
                    ) {
                        // No action - random selection only
                    }
                    .opacity(isRandomizing ? (selectedGameType == gameType ? 1.0 : 0.4) : 0.6)
                    .scaleEffect(isRandomizing && selectedGameType == gameType ? 1.02 : 1.0)
                }
            }
            
            // Info text
            HStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.brandPrimary)
                
                Text("Game will be randomly selected when you start")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.system(size: 18, weight: .bold))
            
            HStack(spacing: 12) {
                ForEach(PuzzleDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button {
            startRandomSelection()
        } label: {
            HStack(spacing: 12) {
                if isRandomizing {
                    ProgressView()
                        .tint(.white)
                    Text("Selecting...")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Start Random Game")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: isRandomizing
                        ? [.orange, .orange.opacity(0.8)]
                        : [.brandPrimary, .brandPrimary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: isRandomizing ? Color.orange.opacity(0.4) : Color.brandPrimary.opacity(0.4),
                radius: 12, x: 0, y: 6
            )
        }
        .disabled(isRandomizing)
        .padding(.top, 8)
    }
    
    // MARK: - Random Selection Logic
    private func startRandomSelection() {
        isRandomizing = true
        var cycleCount = 0
        let totalCycles = 12 // Number of quick cycles before final selection
        
        // Quick cycling through game types
        randomizeTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            cycleCount += 1
            
            // Cycle through game types
            let allTypes = AIGameType.allCases
            let currentIndex = cycleCount % allTypes.count
            
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedGameType = allTypes[currentIndex]
            }
            
            // Slow down near the end
            if cycleCount >= totalCycles {
                timer.invalidate()
                
                // Final random selection after a brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        selectedGameType = allTypes.randomElement()
                    }
                    
                    // Show the game after selection animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isRandomizing = false
                        showGame = true
                    }
                }
            }
        }
    }
}

// MARK: - Game Type Card
private struct GameTypeCard: View {
    let gameType: AIGameType
    let isSelected: Bool
    var isRandomizing: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: gameType.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameType.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(gameType.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 14, height: 14)
                        
                        if isRandomizing {
                            // Pulsing effect during randomization
                            Circle()
                                .stroke(Color.brandPrimary.opacity(0.5), lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .scaleEffect(isRandomizing ? 1.3 : 1.0)
                                .opacity(isRandomizing ? 0 : 1)
                                .animation(.easeOut(duration: 0.5).repeatForever(autoreverses: false), value: isRandomizing)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: isSelected && isRandomizing ? 3 : 2)
            )
            .shadow(color: isSelected && isRandomizing ? Color.brandPrimary.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected && isRandomizing ? 12 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(true) // Disable manual selection - random only
    }
    
    private var gradientColors: [Color] {
        switch gameType {
        case .quiz: return [Color(hex: "4F46E5"), Color(hex: "7C3AED")]
        case .puzzle: return [Color(hex: "059669"), Color(hex: "10B981")]
        case .codeRunner: return [Color(hex: "DC2626"), Color(hex: "F97316")]
        }
    }
}

// MARK: - Difficulty Button
private struct DifficultyButton: View {
    let difficulty: PuzzleDifficulty
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(difficulty.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Stars indicator
                HStack(spacing: 2) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white : difficultyColor)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? AnyShapeStyle(difficultyColor)
                    : AnyShapeStyle(Color(.systemBackground))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(difficultyColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? difficultyColor.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var starCount: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Quick Quiz Game View (Simple AI Quiz)
struct QuickQuizGameView: View {
    let courseId: String
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [GameQuestion] = []
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if showResult {
                resultView
            } else if let question = currentQuestion {
                quizContent(question)
            }
        }
        .task {
            await loadQuestions()
        }
    }
    
    private var currentQuestion: GameQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Generating Quiz...")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("AI is creating questions from the course")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Failed to Load")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.brandPrimary)
                    .cornerRadius(12)
            }
        }
    }
    
    private var resultView: some View {
        VStack(spacing: 32) {
            Image(systemName: score >= questions.count / 2 ? "trophy.fill" : "star.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Quiz Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(score)/\(questions.count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.brandPrimary)
            
            Text(score >= questions.count / 2 ? "Great job!" : "Keep practicing!")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandPrimary)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private func quizContent(_ question: GameQuestion) -> some View {
        VStack(spacing: 24) {
            // Progress
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Question \(currentIndex + 1)/\(questions.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Score: \(score)")
                    .font(.headline)
                    .foregroundColor(.brandPrimary)
            }
            .padding()
            
            Spacer()
            
            // Question
            Text(question.questionText)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Options
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectAnswer(index, correct: question.correctOptionIndex)
                    } label: {
                        Text(option)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(answerColor(for: index, correct: question.correctOptionIndex))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(answerBackground(for: index, correct: question.correctOptionIndex))
                            .cornerRadius(14)
                    }
                    .disabled(selectedAnswer != nil)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func answerColor(for index: Int, correct: Int) -> Color {
        guard let selected = selectedAnswer else { return .white }
        if index == correct { return .white }
        if index == selected { return .white }
        return .white.opacity(0.6)
    }
    
    private func answerBackground(for index: Int, correct: Int) -> Color {
        guard let selected = selectedAnswer else {
            return Color.white.opacity(0.15)
        }
        if index == correct { return .green }
        if index == selected { return .red }
        return Color.white.opacity(0.1)
    }
    
    private func selectAnswer(_ index: Int, correct: Int) {
        selectedAnswer = index
        if index == correct {
            score += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if currentIndex < questions.count - 1 {
                currentIndex += 1
                selectedAnswer = nil
            } else {
                showResult = true
            }
        }
    }
    
    private func loadQuestions() async {
        do {
            questions = try await DIContainer.shared.quizService.generateGameQuestionsFromCourse(courseId: courseId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
