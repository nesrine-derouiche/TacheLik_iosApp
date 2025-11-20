import Foundation
import Combine

@MainActor
final class QuizDetailViewModel: ObservableObject {
    @Published private(set) var detail: QuizDetail?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var selectedAnswers: [String: String] = [:]
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var submitErrorMessage: String?
    @Published private(set) var attemptResult: QuizAttemptResult?

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

    func selectedAnswerId(for questionId: String) -> String? {
        selectedAnswers[questionId]
    }

    func selectAnswer(for questionId: String, answerId: String) {
        selectedAnswers[questionId] = answerId
    }

    var canSubmit: Bool {
        guard let detail else { return false }
        return detail.questions.allSatisfy { selectedAnswers[$0.id] != nil }
    }

    func submitAttempt() async {
        guard !isSubmitting else { return }
        guard canSubmit else {
            submitErrorMessage = "Please answer all questions before submitting."
            return
        }

        isSubmitting = true
        submitErrorMessage = nil

        guard let detail else {
            isSubmitting = false
            submitErrorMessage = "Quiz details are missing. Please try again."
            return
        }

        let payload = detail.questions.compactMap { question -> QuizAnswerSubmission? in
            guard let answerId = selectedAnswers[question.id] else { return nil }
            return QuizAnswerSubmission(questionId: question.id, answerId: answerId)
        }

        do {
            let result = try await quizService.submitAttempt(quizId: quizId, answers: payload)
            attemptResult = result
        } catch let networkError as NetworkError {
            switch networkError {
            case .serverError(let code, let message):
                submitErrorMessage = message ?? "Server error: \(code)"
                if AppConfig.enableLogging {
                    print("❌ [QuizDetailViewModel] Quiz attempt failed with server error code=\(code), message=\(message ?? "nil")")
                }
            default:
                submitErrorMessage = networkError.localizedDescription
                if AppConfig.enableLogging {
                    print("❌ [QuizDetailViewModel] Quiz attempt failed with error: \(networkError)")
                }
            }
        } catch {
            submitErrorMessage = error.localizedDescription
            if AppConfig.enableLogging {
                print("❌ [QuizDetailViewModel] Quiz attempt failed with unexpected error: \(error)")
            }
        }

        isSubmitting = false
    }
}
