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
                        
                        // Game Type Selection
                        gameTypeSection
                        
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
            // AI Icon
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
            }
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            
            Text("Choose Your Game")
                .font(.system(size: 26, weight: .bold))
            
            Text("AI generates unique challenges from\n\"\(courseName)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Game Type Section
    private var gameTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Game Type")
                .font(.system(size: 18, weight: .bold))
            
            VStack(spacing: 12) {
                ForEach(AIGameType.allCases) { gameType in
                    GameTypeCard(
                        gameType: gameType,
                        isSelected: selectedGameType == gameType
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGameType = gameType
                        }
                    }
                }
            }
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
            guard selectedGameType != nil else { return }
            showGame = true
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Start Game")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: selectedGameType != nil
                        ? [.brandPrimary, .brandPrimary.opacity(0.8)]
                        : [.gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: selectedGameType != nil ? Color.brandPrimary.opacity(0.4) : .clear,
                radius: 12, x: 0, y: 6
            )
        }
        .disabled(selectedGameType == nil || isLoading)
        .padding(.top, 8)
    }
}

// MARK: - Game Type Card
private struct GameTypeCard: View {
    let gameType: AIGameType
    let isSelected: Bool
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
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
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
