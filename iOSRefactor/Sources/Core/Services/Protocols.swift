import Foundation

protocol LiveAvatarSessionServiceProtocol {
    func startSession(patientName: String, doctorID: String) async throws -> LiveAvatarSessionPayload
    func stopSession(sessionID: String?) async throws
}

enum ServiceError: LocalizedError {
    case missingConfiguration(String)
    case invalidResponse
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let message),
             .server(let message):
            return message
        case .invalidResponse:
            return "The server returned an invalid response."
        }
    }
}
