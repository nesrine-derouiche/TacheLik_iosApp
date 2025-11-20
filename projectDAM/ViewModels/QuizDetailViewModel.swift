import Foundation
import Combine

@MainActor
final class QuizDetailViewModel: ObservableObject {
    @Published private(set) var detail: QuizDetail?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    let quizId: String

    private let quizService: QuizServiceProtocol

    init(quizId: String, quizService: QuizServiceProtocol) {
        self.quizId = quizId
        self.quizService = quizService
    }

    func loadDetail() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            detail = try await quizService.fetchQuizDetail(id: quizId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func answers(for question: QuizQuestion) -> [QuizAnswer] {
        guard let detail else { return [] }
        return detail.answersByQuestion[question.id] ?? []
    }
}
