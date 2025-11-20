import SwiftUI

struct StudentQuizDetailView: View {
    @StateObject private var viewModel: QuizDetailViewModel

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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header(for: detail)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(detail.questions.enumerated()), id: \.element.id) { index, question in
                            questionCard(question, index: index + 1)
                        }
                    }

                    if let attempt = viewModel.attemptResult {
                        resultCard(for: attempt)
                    }

                    submitSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .padding(.bottom, DS.barHeight + 8)
            }
        } else {
            Text("Quiz unavailable")
                .foregroundColor(.secondary)
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

    private func questionCard(_ question: QuizQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Question \(index)")
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

    private var submitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let message = viewModel.submitErrorMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }

            Button {
                Task {
                    await viewModel.submitAttempt()
                }
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isSubmitting ? "Submitting..." : "Submit Quiz")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(viewModel.canSubmit ? Color.brandPrimary : Color.gray.opacity(0.5))
                .cornerRadius(16)
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
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
}
