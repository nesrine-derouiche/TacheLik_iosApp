import SwiftUI

struct QuizListView: View {
    @StateObject private var viewModel: QuizListViewModel

    init(quizService: QuizServiceProtocol = DIContainer.shared.quizService) {
        _viewModel = StateObject(wrappedValue: QuizListViewModel(quizService: quizService))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.quizzes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.quizzes.isEmpty {
                VStack(spacing: 12) {
                    Text("Unable to load quizzes")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.quizzes.isEmpty {
                Text("No quizzes available yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.quizzes) { quiz in
                    NavigationLink(destination: QuizDetailView(quizId: quiz.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quiz.title)
                                .font(.headline)
                            Text(quiz.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.appGroupedBackground)
            }
        }
        .navigationTitle("Quizzes")
        .navigationBarTitleDisplayMode(.inline)
        .appForceNavigationTitle("Quizzes", displayMode: .never)
        .task {
            await viewModel.loadQuizzes()
        }
    }
}
