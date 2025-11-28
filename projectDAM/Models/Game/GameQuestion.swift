import Foundation

struct GameQuestion: Identifiable, Decodable {
    let id = UUID()
    let questionText: String
    let options: [String] // Should be exactly 3 options
    let correctOptionIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case questionText, options, correctOptionIndex
    }
}

class GameQuestionProvider {
    static let shared = GameQuestionProvider()
    
    private var cachedQuestions: [GameQuestion] = []
    private var currentIndex = 0
    
    func loadQuestionsFromCourse(courseId: String) async throws {
        let quizService = DIContainer.shared.quizService
        let questions = try await quizService.generateGameQuestionsFromCourse(courseId: courseId)
        cachedQuestions = questions
        currentIndex = 0
        print("✅ [GameQuestionProvider] Loaded \(questions.count) questions from course \(courseId)")
    }
    
    func getRandomQuestion() -> GameQuestion? {
        guard !cachedQuestions.isEmpty else {
            return nil
        }
        
        let question = cachedQuestions[currentIndex]
        currentIndex = (currentIndex + 1) % cachedQuestions.count
        return question
    }
    
    func hasQuestions() -> Bool {
        return !cachedQuestions.isEmpty
    }
    
    func reset() {
        cachedQuestions = []
        currentIndex = 0
    }
}
