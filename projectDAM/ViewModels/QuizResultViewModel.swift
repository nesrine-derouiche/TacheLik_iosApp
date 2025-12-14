import Foundation
import Combine

@MainActor
class QuizResultViewModel: ObservableObject {
    @Published var isLoadingExplanation = false
    @Published var explanation: ExplainMistakesResponse?
    @Published var explanationError: String?
    
    private let quizService: QuizServiceProtocol
    
    init(quizService: QuizServiceProtocol = DIContainer.shared.quizService) {
        self.quizService = quizService
    }
    
    func fetchExplanation(attemptId: String) async {
        isLoadingExplanation = true
        explanationError = nil
        
        do {
            let response = try await quizService.explainQuizMistakes(attemptId: attemptId)
            explanation = response
            isLoadingExplanation = false
        } catch {
            explanationError = error.localizedDescription
            isLoadingExplanation = false
        }
    }
    
    func clearExplanation() {
        explanation = nil
        explanationError = nil
    }
}
