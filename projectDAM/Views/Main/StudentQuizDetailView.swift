import SwiftUI

struct StudentQuizDetailView: View {
    @StateObject private var viewModel: QuizDetailViewModel
    @StateObject private var resultViewModel = QuizResultViewModel()
    @State private var showExplanationSheet = false
    @State private var currentQuestionIndex: Int = 0

    init(quizId: String, quizService: QuizServiceProtocol = DIContainer.shared.quizService) {
        _viewModel = StateObject(wrappedValue: QuizDetailViewModel(quizId: quizId, quizService: quizService))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            content
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetail()
        }
        .sheet(isPresented: $showExplanationSheet, onDismiss: {
            resultViewModel.clearExplanation()
        }) {
            ExplanationSheetView(viewModel: resultViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.detail == nil {
            ProgressView()
        } else if let error = viewModel.errorMessage, viewModel.detail == nil {
            VStack(spacing: 8) {
                Text("Unable to load quiz")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        } else if let detail = viewModel.detail {
            ZStack {
                if let attempt = viewModel.attemptResult {
                    resultScreen(for: attempt, detail: detail)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    questionFlow(for: detail)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .padding(.bottom, DS.barHeight + 8)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.attemptResult?.attemptId)
        } else {
            Text("Quiz unavailable")
                .foregroundColor(.secondary)
        }
    }

    private func questionFlow(for detail: QuizDetail) -> some View {
        let questions = detail.questions
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header(for: detail)

                if !questions.isEmpty {
                    progressHeader(current: currentQuestionIndex + 1, total: questions.count)
                    questionCard(questions[currentQuestionIndex], index: currentQuestionIndex + 1, total: questions.count)
                    navigationSection(for: questions)
                } else {
                    Text("No questions available for this quiz.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func header(for detail: QuizDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail.quiz.title)
                .font(.system(size: 22, weight: .bold))
            Text(detail.quiz.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    private func progressHeader(current: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(current) of \(total)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)

                    let progress = CGFloat(current) / CGFloat(max(total, 1))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func questionCard(_ question: QuizQuestion, index: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Question \(index) / \(total)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.brandPrimary)
                Spacer()
            }

            Text(question.text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            let answers = viewModel.answers(for: question)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(answers) { answer in
                    answerRow(questionId: question.id, answer: answer)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private func answerRow(questionId: String, answer: QuizAnswer) -> some View {
        let isSelected = viewModel.selectedAnswerId(for: questionId) == answer.id

        return Button {
            viewModel.selectAnswer(for: questionId, answerId: answer.id)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .brandPrimary : .secondary)
                    .font(.system(size: 18, weight: .semibold))

                Text(answer.text)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 15))

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.brandPrimary.opacity(0.08) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func navigationSection(for questions: [QuizQuestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let message = viewModel.submitErrorMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentQuestionIndex = max(0, currentQuestionIndex - 1)
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(currentQuestionIndex == 0 ? .secondary : .brandPrimary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .disabled(currentQuestionIndex == 0)

                Spacer()

                let isLast = currentQuestionIndex == questions.count - 1
                let currentQuestion = questions[currentQuestionIndex]
                let hasAnswer = viewModel.selectedAnswerId(for: currentQuestion.id) != nil

                Button {
                    if isLast {
                        Task { await viewModel.submitAttempt() }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentQuestionIndex = min(questions.count - 1, currentQuestionIndex + 1)
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSubmitting && isLast {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLast ? (viewModel.isSubmitting ? "Submitting..." : "Submit Quiz") : "Next")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: isLast ? "paperplane.fill" : "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background((hasAnswer && !viewModel.isSubmitting) ? Color.brandPrimary : Color.gray.opacity(0.5))
                    .cornerRadius(18)
                }
                .disabled(!hasAnswer || viewModel.isSubmitting)
            }
        }
    }

    private func resultCard(for attempt: QuizAttemptResult) -> some View {
        let message: String = {
            switch attempt.score {
            case 90...100: return "Outstanding work!"
            case 70..<90:  return "Great job, keep it up!"
            case 50..<70:  return "Nice effort, you\'re getting there."
            default:       return "Good start, try again to improve your score."
            }
        }()

        return VStack(alignment: .leading, spacing: 16) {
            Text("Your Result")
                .font(.system(size: 17, weight: .bold))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(attempt.score)%")
                        .font(.system(size: 20, weight: .bold))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Correct")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(attempt.correctCount) / \(attempt.totalQuestions)")
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            if !attempt.awardedBadges.isEmpty {
                Divider().padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("New Badges")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 8) {
                        ForEach(attempt.awardedBadges, id: \.id) { awarded in
                            Text(awarded.badge.name)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.brandPrimary.opacity(0.12))
                                )
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
    }

    private func resultScreen(for attempt: QuizAttemptResult, detail: QuizDetail) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Quiz Completed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(detail.quiz.title)
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .shadow(color: Color.brandPrimary.opacity(0.35), radius: 20, x: 0, y: 10)

                        VStack(spacing: 6) {
                            Text("\(attempt.score)%")
                                .font(.system(size: 44, weight: .black))
                                .foregroundColor(.white)
                            Text("Score")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 8)

                    resultCard(for: attempt)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // AI Assistance Section
                    VStack(spacing: 12) {
                        Text("Need help understanding your mistakes?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        // AI Bubble
                        Button(action: {
                            Task {
                                await resultViewModel.fetchExplanation(attemptId: attempt.attemptId)
                                showExplanationSheet = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                // AI Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                    
                                    if resultViewModel.isLoadingExplanation {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Text Content
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(resultViewModel.isLoadingExplanation ? "Analyzing..." : "Ask AI for Help")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Get personalized explanations for your mistakes")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                // Arrow Icon
                                if !resultViewModel.isLoadingExplanation {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .opacity(resultViewModel.isLoadingExplanation ? 0.8 : 1.0)
                        }
                        .disabled(resultViewModel.isLoadingExplanation)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
    }
}
