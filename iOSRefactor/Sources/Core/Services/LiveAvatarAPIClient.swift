import Foundation

final class LiveAvatarAPIClient: LiveAvatarSessionServiceProtocol {
    private let environment: AppEnvironment
    private let session: URLSession

    init(environment: AppEnvironment, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
    }

    func startSession(patientName: String, doctorID: String) async throws -> LiveAvatarSessionPayload {
        guard !environment.liveAvatarAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingConfiguration(
                "Missing LiveAvatar API key. Fill in Config/Secrets.xcconfig before starting a paid session."
            )
        }

        let config = DoctorDirectory.liveAvatarConfig(for: doctorID)

        let tokenResponse: LiveAvatarTokenResponse = try await performRequest(
            path: "sessions/token",
            method: "POST",
            body: LiveAvatarTokenRequest(
                avatarID: config.avatarID,
                avatarPersona: LiveAvatarPersonaRequest(voiceID: config.voiceID)
            ),
            headers: ["X-API-KEY": environment.liveAvatarAPIKey]
        )

        guard let sessionToken = tokenResponse.data?.sessionToken else {
            throw ServiceError.server(message: tokenResponse.message ?? "Missing LiveAvatar session token.")
        }

        let startResponse: LiveAvatarStartResponse = try await performRequest(
            path: "sessions/start",
            method: "POST",
            body: Optional<String>.none,
            headers: ["Authorization": "Bearer \(sessionToken)"]
        )

        guard let startData = startResponse.data else {
            throw ServiceError.server(message: startResponse.message ?? "Missing LiveAvatar start session payload.")
        }

        return LiveAvatarSessionPayload(
            sessionID: startData.sessionID,
            sessionToken: sessionToken,
            livekitURL: startData.livekitURL,
            livekitClientToken: startData.livekitClientToken,
            maxSessionDuration: startData.maxSessionDuration,
            avatarID: config.avatarID,
            voiceID: config.voiceID
        )
    }

    func stopSession(sessionID: String?) async throws {
        guard let sessionID, !sessionID.isEmpty else {
            return
        }

        _ = try await performRequest(
            path: "sessions/stop",
            method: "POST",
            body: LiveAvatarAPIStopRequest(sessionID: sessionID),
            headers: ["X-API-KEY": environment.liveAvatarAPIKey]
        ) as LiveAvatarStopResponse
    }

    func speak(text: String, in session: LiveAvatarSessionPayload, taskType: AvatarSpeechTaskType = .repeat) async throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }

        guard let sessionID = session.sessionID, !sessionID.isEmpty else {
            throw ServiceError.invalidResponse
        }

        try await performVoidRequest(
            baseURL: environment.avatarSpeechAPIBaseURL,
            path: environment.avatarSpeechTaskPath,
            method: "POST",
            body: AvatarSpeechTaskRequest(
                sessionID: sessionID,
                text: trimmedText,
                taskType: taskType
            ),
            headers: ["Authorization": "Bearer \(session.sessionToken)"]
        )
    }

    private func performRequest<ResponseType: Decodable, BodyType: Encodable>(
        path: String,
        method: String,
        body: BodyType?,
        headers: [String: String]
    ) async throws -> ResponseType {
        let url = environment.liveAvatarAPIBaseURL.appending(path: path)
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

    private func performVoidRequest<BodyType: Encodable>(
        baseURL: URL,
        path: String,
        method: String,
        body: BodyType?,
        headers: [String: String]
    ) async throws {
        let url = baseURL.appending(path: path)
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

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw ServiceError.server(message: message)
        }
    }
}
