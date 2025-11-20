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
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}
