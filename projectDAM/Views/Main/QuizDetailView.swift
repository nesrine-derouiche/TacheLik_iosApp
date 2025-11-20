import SwiftUI

struct QuizDetailView: View {
    @StateObject private var viewModel: QuizDetailViewModel

    init(quizId: String, quizService: QuizServiceProtocol = DIContainer.shared.quizService) {
        _viewModel = StateObject(wrappedValue: QuizDetailViewModel(quizId: quizId, quizService: quizService))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.detail == nil {
                VStack(spacing: 12) {
                    Text("Unable to load quiz")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(detail.quiz.title)
                                .font(.title2.bold())
                            Text(detail.quiz.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ForEach(detail.questions) { question in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(question.text)
                                    .font(.headline)

                                let answers = viewModel.answers(for: question)
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(answers) { answer in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(answer.isCorrect ? .green : .secondary)
                                            Text(answer.text)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Quiz")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Quiz unavailable")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadDetail()
        }
    }
}
