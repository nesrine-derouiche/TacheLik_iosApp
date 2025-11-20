import SwiftUI

struct StudentQuizDetailView: View {
    @StateObject private var viewModel: QuizDetailViewModel
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Result")
                .font(.system(size: 16, weight: .bold))

            Text("Score: \(attempt.score)%")
                .font(.system(size: 15, weight: .semibold))

            Text("Correct: \(attempt.correctCount) / \(attempt.totalQuestions)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if !attempt.awardedBadges.isEmpty {
                Divider().padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("New Badges")
                        .font(.system(size: 14, weight: .semibold))

                    ForEach(attempt.awardedBadges, id: \.id) { awarded in
                        Text("• \(awarded.badge.name)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.brandPrimary.opacity(0.08))
        )
    }

    private func resultScreen(for attempt: QuizAttemptResult, detail: QuizDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 24) {
                header(for: detail)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 16, x: 0, y: 8)

                    VStack(spacing: 6) {
                        Text("\(attempt.score)%")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.white)
                        Text("Score")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.top, 16)

                resultCard(for: attempt)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
        }
    }
}
