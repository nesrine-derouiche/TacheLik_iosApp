import SwiftUI

struct StudentQuizListView: View {
    @StateObject private var viewModel: QuizListViewModel
    @State private var selectedAttempt: QuizAttemptSummary?
    @State private var selectedQuiz: QuizSummary?
    @State private var navigateToQuiz: Bool = false

    init(quizService: QuizServiceProtocol = DIContainer.shared.quizService) {
        _viewModel = StateObject(wrappedValue: QuizListViewModel(quizService: quizService))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Quizzes")
            .navigationBarTitleDisplayMode(.large)
            .background(
                NavigationLink(
                    destination: Group {
                        if let quiz = selectedQuiz {
                            StudentQuizDetailView(quizId: quiz.id)
                        }
                    },
                    isActive: Binding(
                        get: { navigateToQuiz },
                        set: { isActive in
                            if !isActive {
                                navigateToQuiz = false
                                selectedQuiz = nil
                            }
                        }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
        .task {
            await viewModel.loadQuizzes()
        }
        .sheet(item: $selectedAttempt) { attempt in
            if let quiz = selectedQuiz {
                QuizAttemptPreviewSheet(
                    quiz: quiz,
                    attempt: attempt,
                    onRetake: {
                        selectedAttempt = nil
                        navigateToQuiz = true
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.quizzes.isEmpty {
            ProgressView()
        } else if let error = viewModel.errorMessage, viewModel.quizzes.isEmpty {
            VStack(spacing: 8) {
                Text("Unable to load quizzes")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        } else if viewModel.quizzes.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("No quizzes available yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(viewModel.quizzes) { quiz in
                        if let attempt = viewModel.attemptsByQuizId[quiz.id] {
                            Button {
                                selectedQuiz = quiz
                                selectedAttempt = attempt
                            } label: {
                                quizCard(for: quiz, attempt: attempt)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: StudentQuizDetailView(quizId: quiz.id)) {
                                quizCard(for: quiz, attempt: nil)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, DS.barHeight + 8)
            }
        }
    }

    private func quizCard(for quiz: QuizSummary, attempt: QuizAttemptSummary?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quiz.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Text(quiz.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(3)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                Text("AI Generated Quiz")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandPrimary)

                Spacer()

                if let attempt {
                    Text("Last: \(attempt.score)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}
