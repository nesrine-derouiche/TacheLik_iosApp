import Foundation

struct QuizSummary: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct QuizQuestion: Identifiable, Decodable {
    let id: String
    let text: String
}

struct QuizAnswer: Identifiable, Decodable {
    let id: String
    let text: String
    let isCorrect: Bool
    let question: QuizQuestion?

    enum CodingKeys: String, CodingKey {
        case id, text, question
        case isCorrect = "is_correct"
    }
}

struct QuizDetail: Decodable {
    let quiz: QuizSummary
    let questions: [QuizQuestion]
    let answersByQuestion: [String: [QuizAnswer]]
    let success: Bool
}

struct QuizAnswerSubmission {
    let questionId: String
    let answerId: String
}

struct QuizAttemptResult: Decodable {
    let attemptId: String
    let score: Int
    let correctCount: Int
    let totalQuestions: Int
    let awardedBadges: [AwardedBadge]
}

struct AwardedBadge: Decodable {
    let id: String
    let badge: Badge
    let awardedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, badge
        case awardedAt = "awarded_at"
    }
}

struct Badge: Decodable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let criteria: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case iconUrl = "icon_url"
        case criteria
    }
}

struct QuizAttemptSummary: Identifiable, Decodable {
    let id: String
    let quiz: QuizSummary
    let score: Int
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id, quiz, score
        case completedAt = "completed_at"
    }
}

struct BadgeLeaderboardEntry: Identifiable, Decodable {
    let id: String
    let username: String
    let badgeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case username
        case badgeCount
    }
}

struct BadgeLeaderboardPage: Decodable {
    let leaderboard: [BadgeLeaderboardEntry]
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let success: Bool
}

// MARK: - Quiz Mistake Explanation Models

struct MistakeExplanation: Codable, Identifiable {
    let id = UUID()
    let questionText: String
    let yourAnswer: String
    let correctAnswer: String
    let explanation: String
    
    enum CodingKeys: String, CodingKey {
        case questionText, yourAnswer, correctAnswer, explanation
    }
}

struct ExplainMistakesResponse: Codable {
    let success: Bool
    let explanation: String?
    let mistakes: [MistakeExplanation]?
    let message: String?
}
