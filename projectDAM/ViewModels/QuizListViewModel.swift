import Foundation
import Combine

@MainActor
final class QuizListViewModel: ObservableObject {
    @Published private(set) var quizzes: [QuizSummary] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let quizService: QuizServiceProtocol

    init(quizService: QuizServiceProtocol) {
        self.quizService = quizService
    }

    func loadQuizzes() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            quizzes = try await quizService.fetchQuizzes()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
