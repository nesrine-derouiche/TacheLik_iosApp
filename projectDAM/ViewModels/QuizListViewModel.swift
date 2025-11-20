import Foundation
import Combine

@MainActor
final class QuizListViewModel: ObservableObject {
    @Published private(set) var quizzes: [QuizSummary] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var attemptsByQuizId: [String: QuizAttemptSummary] = [:]

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

            do {
                let attempts = try await quizService.fetchMyAttempts()
                attemptsByQuizId = Dictionary(uniqueKeysWithValues: attempts.map { ($0.quiz.id, $0) })
            } catch {
                if AppConfig.enableLogging {
                    print("⚠️ [QuizListViewModel] Failed to load quiz attempts: \(error)")
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
