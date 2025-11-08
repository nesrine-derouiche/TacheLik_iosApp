//
//  NetworkService+Debug.swift
//  projectDAM
//
//  Enhanced networking with debug logging
//

import Foundation

extension NetworkService {
    /// Enable detailed logging for debugging backend connection
    static var debugMode: Bool = true
    
    static func logRequest(method: HTTPMethod, url: URL, body: Data?) {
        guard debugMode else { return }
        print("\n🌐 ============ API REQUEST ============")
        print("📍 \(method.rawValue) \(url.absoluteString)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Request Body:")
            print(bodyString)
        }
        print("======================================\n")
    }
    
    static func logResponse(statusCode: Int, data: Data) {
        guard debugMode else { return }
        print("\n📥 ============ API RESPONSE ===========")
        print("📊 Status Code: \(statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Response Data:")
            print(jsonString)
        }
        print("======================================\n")
    }
    
    static func logError(_ error: Error) {
        guard debugMode else { return }
        print("\n❌ ============ API ERROR =============")
        print("⚠️ Error: \(error.localizedDescription)")
        print("======================================\n")
    }
}
