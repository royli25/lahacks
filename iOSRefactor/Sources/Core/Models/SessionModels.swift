import Foundation

struct StartRequest: Codable, Hashable {
    let profileID: String
    let userName: String
    let language: String
    let deterministicGreeting: Bool

    init(
        profileID: String,
        userName: String,
        language: String = "en",
        deterministicGreeting: Bool = false
    ) {
        self.profileID = profileID
        self.userName = userName
        self.language = language
        self.deterministicGreeting = deterministicGreeting
    }

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case userName = "user_name"
        case language
        case deterministicGreeting = "deterministic_greeting"
    }
}

struct LiveAvatarPersonaRequest: Codable, Hashable {
    let voiceID: String
    let contextID: String?
    let language: String

    init(voiceID: String, contextID: String? = nil, language: String = "en") {
        self.voiceID = voiceID
        self.contextID = contextID
        self.language = language
    }

    enum CodingKeys: String, CodingKey {
        case voiceID = "voice_id"
        case contextID = "context_id"
        case language
    }
}

struct LiveAvatarTokenRequest: Codable, Hashable {
    static let fullMode = "FULL"

    let mode: String
    let avatarID: String
    let avatarPersona: LiveAvatarPersonaRequest

    init(avatarID: String, avatarPersona: LiveAvatarPersonaRequest) {
        self.mode = Self.fullMode
        self.avatarID = avatarID
        self.avatarPersona = avatarPersona
    }

    init(mode: String, avatarID: String, avatarPersona: LiveAvatarPersonaRequest) {
        self.mode = mode
        self.avatarID = avatarID
        self.avatarPersona = avatarPersona
    }

    enum CodingKeys: String, CodingKey {
        case mode
        case avatarID = "avatar_id"
        case avatarPersona = "avatar_persona"
    }
}

struct LiveAvatarTokenData: Codable, Hashable {
    let sessionToken: String

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
    }
}

struct LiveAvatarTokenResponse: Codable, Hashable {
    let data: LiveAvatarTokenData?
    let message: String?
}

struct LiveAvatarStartData: Codable, Hashable {
    let sessionID: String
    let livekitURL: String
    let livekitClientToken: String
    let maxSessionDuration: Int

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case livekitURL = "livekit_url"
        case livekitClientToken = "livekit_client_token"
        case maxSessionDuration = "max_session_duration"
    }
}

struct LiveAvatarStartResponse: Codable, Hashable {
    let data: LiveAvatarStartData?
    let message: String?
}

struct LiveAvatarSessionPayload: Codable, Hashable {
    let sessionID: String?
    let sessionToken: String
    let livekitURL: String?
    let livekitClientToken: String?
    let maxSessionDuration: Int
    let avatarID: String?
    let voiceID: String?

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId"
        case sessionToken
        case livekitURL = "livekitUrl"
        case livekitClientToken
        case maxSessionDuration
        case avatarID
        case voiceID
    }
}

struct LiveAvatarAPIStopRequest: Codable, Hashable {
    let sessionID: String?
    let reason: String

    init(sessionID: String?, reason: String = "USER_CLOSED") {
        self.sessionID = sessionID
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case reason
    }
}

struct LiveAvatarStopResponse: Codable, Hashable {
    let ok: Bool
    let stoppedSessionIDs: [String]

    enum CodingKeys: String, CodingKey {
        case ok
        case stoppedSessionIDs = "stopped_session_ids"
    }
}

struct AvatarSpeechTaskRequest: Codable, Hashable {
    let sessionID: String
    let text: String
    let taskType: AvatarSpeechTaskType

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case text
        case taskType = "task_type"
    }
}
