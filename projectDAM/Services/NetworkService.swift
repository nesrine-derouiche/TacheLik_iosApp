//
//  NetworkService.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import Combine

// MARK: - Error Response Model
struct ErrorResponse: Decodable {
    let message: String?
    let success: Bool?
}

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(Int, String?)
    case noData
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .decodingError: return "Failed to decode response"
        case .serverError(let code, let message):
            return message ?? "Server error: \(code)"
        case .noData: return "No data received"
        case .unauthorized: return "Unauthorized access"
        }
    }
}

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String]?
    ) async throws -> T

    func upload<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        multipart: MultipartFormData,
        headers: [String: String]?
    ) async throws -> T
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - Network Service Implementation
final class NetworkService: NetworkServiceProtocol {

    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession

    // MARK: - Initialization
    init(baseURL: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL ?? AppConfig.baseURL
        self.session = session
    }

    // MARK: - Request Method
    /// Performs a network request and decodes the response
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {

        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [NetworkService] Invalid HTTP response for \(url)")
                throw NetworkError.invalidResponse
            }
            
            print("📡 [NetworkService] Response status: \(httpResponse.statusCode) for \(endpoint)")

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return decoded
                } catch {
                    // Log the actual response for debugging
                    print("❌ [NetworkService] Decoding error for \(url)")
                    print("❌ [NetworkService] Error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("❌ [NetworkService] Response JSON: \(jsonString)")
                    }
                    throw NetworkError.decodingError
                }
            case 401:
                throw NetworkError.unauthorized
            default:
                // Try to parse error message from response
                let errorMessage: String?
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    errorMessage = errorResponse.message
                } else {
                    errorMessage = nil
                }
                throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch let urlError as URLError {
            print("❌ [NetworkService] URLError for \(url): \(urlError.localizedDescription)")
            print("❌ [NetworkService] Error code: \(urlError.code.rawValue)")
            if urlError.code == .notConnectedToInternet {
                throw NetworkError.serverError(0, "No internet connection")
            } else if urlError.code == .cannotConnectToHost {
                throw NetworkError.serverError(0, "Cannot connect to server. Is the backend running?")
            } else if urlError.code == .timedOut {
                throw NetworkError.serverError(0, "Request timed out")
            }
            throw NetworkError.serverError(0, urlError.localizedDescription)
        }
    }

    // MARK: - Upload Method (multipart)
    func upload<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .POST,
        multipart: MultipartFormData,
        headers: [String: String]? = nil
    ) async throws -> T {

        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Build body and set content type
        let bodyData = multipart.buildBody()
        request.httpBody = bodyData
        request.setValue(multipart.contentTypeHeader(), forHTTPHeaderField: "Content-Type")

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            let errorMessage: String?
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                errorMessage = errorResponse.message
            } else {
                errorMessage = nil
            }
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
    }
}
