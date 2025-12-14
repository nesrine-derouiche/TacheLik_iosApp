import Foundation

enum HomeErrorFormatter {
    static func message(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                return "Please log in again."
            case .serverError(let code, let message):
                if code == 0 {
                    return message ?? "You appear to be offline."
                }
                return message ?? "Server error (\(code))."
            case .invalidResponse:
                return "Network error. Please try again shortly."
            case .decodingError:
                return "We couldn't process the latest data."
            case .invalidURL:
                return "App configuration error."
            case .noData:
                return "No data received."
            }
        }
        return error.localizedDescription
    }
}
