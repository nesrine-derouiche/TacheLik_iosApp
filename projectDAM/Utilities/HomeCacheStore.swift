import Foundation

struct CachedEnvelope<T: Codable>: Codable {
    let savedAt: Date
    let value: T
}

final class HomeCacheStore {
    enum CacheKey: String {
        case studentHomeV1
        case teacherHomeV1
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save<T: Codable>(_ value: T, for key: CacheKey) throws {
        let envelope = CachedEnvelope(savedAt: Date(), value: value)
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL(for: key), options: [.atomic])
    }

    func load<T: Codable>(_ type: T.Type, for key: CacheKey) -> CachedEnvelope<T>? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(CachedEnvelope<T>.self, from: data)
    }

    private func fileURL(for key: CacheKey) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("tachelik_\(key.rawValue).json")
    }
}
