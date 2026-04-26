import Foundation

final class BackendAPIClient: BackendServiceProtocol {
    private let environment: AppEnvironment
    private let session: URLSession

    init(environment: AppEnvironment, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func registerPatient(request: NewPatientRequest) async throws -> PatientResponse {
        try await performRequest(
            path: "api/new-patient",
            method: "POST",
            body: request,
            headers: [:]
        )
    }

    func fetchPatient(uid: String) async throws -> PatientLookupResponse {
        try await performRequest(
            path: "api/patient/\(uid)",
            method: "GET",
            body: Optional<String>.none,
            headers: [:]
        )
    }

    func summarizeTranscript(request: TranscriptSummaryRequest) async throws -> SummaryResponse {
        try await performRequest(
            path: "api/summarize-transcript",
            method: "POST",
            body: request,
            headers: [:]
        )
    }

    private func performRequest<ResponseType: Decodable, BodyType: Encodable>(
        path: String,
        method: String,
        body: BodyType?,
        headers: [String: String]
    ) async throws -> ResponseType {
        let url = environment.backendBaseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(ResponseType.self, from: data)
        }

        let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
        throw ServiceError.server(message: message)
    }
}

