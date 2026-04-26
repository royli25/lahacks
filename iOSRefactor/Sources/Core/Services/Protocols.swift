import Foundation

protocol BackendServiceProtocol {
    func registerPatient(request: NewPatientRequest) async throws -> PatientResponse
    func fetchPatient(uid: String) async throws -> PatientLookupResponse
    func summarizeTranscript(request: TranscriptSummaryRequest) async throws -> SummaryResponse
}

protocol LiveAvatarSessionServiceProtocol {
    func startSession(patientName: String, doctorID: String) async throws -> LiveAvatarSessionPayload
    func stopSession(sessionID: String?) async throws
}

protocol TranscriptCaptureServiceProtocol {
    func requestPermissions() async throws
    func beginCapture() async throws
    func stopCapture()
}

enum ServiceError: LocalizedError {
    case missingConfiguration(String)
    case invalidResponse
    case server(message: String)
    case unsupported(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let message),
             .server(let message),
             .unsupported(let message):
            return message
        case .invalidResponse:
            return "The server returned an invalid response."
        }
    }
}

