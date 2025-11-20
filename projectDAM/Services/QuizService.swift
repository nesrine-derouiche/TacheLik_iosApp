import Foundation

protocol QuizServiceProtocol {
    func fetchQuizzes() async throws -> [QuizSummary]
    func fetchQuizDetail(id: String) async throws -> QuizDetail
}

final class QuizService: QuizServiceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchQuizzes() async throws -> [QuizSummary] {
        if AppConfig.enableLogging {
            print("📡 [QuizService] Requesting quizzes at GET /quiz")
        }
        struct QuizzesResponse: Decodable {
            let success: Bool
            let quizzes: [QuizSummary]
        }
        let response: QuizzesResponse = try await networkService.request(
            endpoint: "/quiz",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [QuizService] Received \(response.quizzes.count) quizzes")
        }
        return response.quizzes
    }

    func fetchQuizDetail(id: String) async throws -> QuizDetail {
        if AppConfig.enableLogging {
            print("📡 [QuizService] Requesting quiz detail at GET /quiz/\(id)")
        }
        let detail: QuizDetail = try await networkService.request(
            endpoint: "/quiz/\(id)",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [QuizService] Received quiz detail for id=\(detail.quiz.id)")
        }
        return detail
    }
}
