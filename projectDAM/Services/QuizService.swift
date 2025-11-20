import Foundation

protocol QuizServiceProtocol {
    func fetchQuizzes() async throws -> [QuizSummary]
    func fetchQuizDetail(id: String) async throws -> QuizDetail
    func submitAttempt(quizId: String, answers: [QuizAnswerSubmission]) async throws -> QuizAttemptResult
    func fetchMyAttempts() async throws -> [QuizAttemptSummary]
    func generateQuizFromCourse(courseId: String, title: String?, description: String?) async throws -> QuizSummary
    func generateQuizFromVideos(videoIds: [String], title: String?, description: String?) async throws -> QuizSummary
}

final class QuizService: QuizServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol

    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
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

    func submitAttempt(quizId: String, answers: [QuizAnswerSubmission]) async throws -> QuizAttemptResult {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        if AppConfig.enableLogging {
            print("📡 [QuizService] Submitting quiz attempt at POST /quiz/\(quizId)/attempt with \(answers.count) answers")
        }

        struct AttemptAnswerPayload: Encodable {
            let questionId: String
            let answerId: String
        }

        struct AttemptRequest: Encodable {
            let answers: [AttemptAnswerPayload]
        }

        struct Attempt: Decodable {
            let id: String
            let score: Int
            let completedAt: String

            enum CodingKeys: String, CodingKey {
                case id, score
                case completedAt = "completed_at"
            }
        }

        struct AttemptResponse: Decodable {
            let success: Bool
            let attempt: Attempt
            let score: Int
            let correctCount: Int
            let totalQuestions: Int
            let awardedBadges: [AwardedBadge]

            enum CodingKeys: String, CodingKey {
                case success, attempt, score, correctCount, totalQuestions, awardedBadges
            }
        }

        let payload = AttemptRequest(answers: answers.map { AttemptAnswerPayload(questionId: $0.questionId, answerId: $0.answerId) })
        let body = try JSONEncoder().encode(payload)

        if AppConfig.enableLogging,
           let jsonString = String(data: body, encoding: .utf8) {
            print("📦 [QuizService] Attempt payload: \(jsonString)")
        }

        let response: AttemptResponse = try await networkService.request(
            endpoint: "/quiz/\(quizId)/attempt",
            method: .POST,
            body: body,
            headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"]
        )

        if AppConfig.enableLogging {
            print("✅ [QuizService] Quiz attempt submitted id=\(response.attempt.id), score=\(response.score)")
        }

        return QuizAttemptResult(
            attemptId: response.attempt.id,
            score: response.score,
            correctCount: response.correctCount,
            totalQuestions: response.totalQuestions,
            awardedBadges: response.awardedBadges
        )
    }

    func fetchMyAttempts() async throws -> [QuizAttemptSummary] {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        if AppConfig.enableLogging {
            print("📡 [QuizService] Requesting my quiz attempts at GET /quiz/attempts/me")
        }

        struct AttemptsResponse: Decodable {
            let success: Bool
            let attempts: [QuizAttemptSummary]
        }

        let response: AttemptsResponse = try await networkService.request(
            endpoint: "/quiz/attempts/me",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )

        if AppConfig.enableLogging {
            print("✅ [QuizService] Received \(response.attempts.count) quiz attempts for current user")
        }

        return response.attempts
    }

    func generateQuizFromCourse(courseId: String, title: String?, description: String?) async throws -> QuizSummary {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        if AppConfig.enableLogging {
            print("📡 [QuizService] Generating quiz from course at POST /quiz/ai/from-course (courseId=\(courseId))")
        }

        struct GenerateFromCourseRequest: Encodable {
            let courseId: String
            let title: String?
            let description: String?
        }

        struct GenerateFromCourseResponse: Decodable {
            let success: Bool
            let quiz: QuizSummary
        }

        let payload = GenerateFromCourseRequest(
            courseId: courseId,
            title: (title?.isEmpty == true) ? nil : title,
            description: (description?.isEmpty == true) ? nil : description
        )
        let body = try JSONEncoder().encode(payload)

        let response: GenerateFromCourseResponse = try await networkService.request(
            endpoint: "/quiz/ai/from-course",
            method: .POST,
            body: body,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ]
        )

        if AppConfig.enableLogging {
            print("✅ [QuizService] Generated quiz from course id=\(response.quiz.id)")
        }

        return response.quiz
    }

    func generateQuizFromVideos(videoIds: [String], title: String?, description: String?) async throws -> QuizSummary {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }

        if AppConfig.enableLogging {
            print("📡 [QuizService] Generating quiz from videos at POST /quiz/ai/from-videos (count=\(videoIds.count))")
        }

        struct GenerateFromVideosRequest: Encodable {
            let videoIds: [String]
            let title: String?
            let description: String?
        }

        struct GenerateFromVideosResponse: Decodable {
            let success: Bool
            let quiz: QuizSummary
        }

        let payload = GenerateFromVideosRequest(
            videoIds: videoIds,
            title: (title?.isEmpty == true) ? nil : title,
            description: (description?.isEmpty == true) ? nil : description
        )
        let body = try JSONEncoder().encode(payload)

        let response: GenerateFromVideosResponse = try await networkService.request(
            endpoint: "/quiz/ai/from-videos",
            method: .POST,
            body: body,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ]
        )

        if AppConfig.enableLogging {
            print("✅ [QuizService] Generated quiz from videos id=\(response.quiz.id)")
        }

        return response.quiz
    }
}
