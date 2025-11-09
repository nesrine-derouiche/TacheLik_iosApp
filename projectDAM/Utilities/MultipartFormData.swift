import Foundation

struct MultipartFormData {
    struct File {
        let fieldName: String
        let fileName: String
        let mimeType: String
        let data: Data
    }
    
    private(set) var fields: [(name: String, value: String)] = []
    private(set) var files: [File] = []
    private let boundary: String
    
    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }
    
    mutating func addField(name: String, value: String) {
        fields.append((name: name, value: value))
    }
    
    mutating func addFile(fieldName: String, fileName: String, mimeType: String, data: Data) {
        let file = File(fieldName: fieldName, fileName: fileName, mimeType: mimeType, data: data)
        files.append(file)
    }
    
    func buildBody() -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for field in fields {
            body.append(boundaryPrefix)
            body.append("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            body.append("\(field.value)\r\n")
        }
        
        for file in files {
            body.append(boundaryPrefix)
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    func contentTypeHeader() -> String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
