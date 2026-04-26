import Foundation

private let defaultLiveAvatarContextID = "567e8371-f69f-49ec-9f2d-054083431165"

struct AppEnvironment {
    let backendBaseURL: URL
    let liveAvatarAPIBaseURL: URL
    let liveAvatarAPIKey: String
    let liveAvatarContextIDs: [String: String]
    let avatarSpeechAPIBaseURL: URL
    let avatarSpeechTaskPath: String

    static func current(bundle: Bundle = .main) -> AppEnvironment {
        current(infoDictionary: bundle.infoDictionary ?? [:])
    }

    static func current(infoDictionary: [String: Any]) -> AppEnvironment {
        let backendBaseURL = URL(
            string: sanitizedConfigurationValue(infoDictionary["BackendBaseURL"] as? String)
                ?? "http://127.0.0.1:8000/"
        ) ?? URL(string: "http://127.0.0.1:8000/")!

        let liveAvatarBaseURL = URL(
            string: sanitizedConfigurationValue(infoDictionary["LiveAvatarAPIBaseURL"] as? String)
                ?? "https://api.liveavatar.com/v1/"
        ) ?? URL(string: "https://api.liveavatar.com/v1/")!

        let liveAvatarAPIKey = sanitizedConfigurationValue(infoDictionary["LiveAvatarAPIKey"] as? String) ?? ""
        let liveAvatarContextIDs = [
            "alpha": sanitizedConfigurationValue(infoDictionary["LiveAvatarAlphaContextID"] as? String),
            "beta": sanitizedConfigurationValue(infoDictionary["LiveAvatarBetaContextID"] as? String),
            "gamma": sanitizedConfigurationValue(infoDictionary["LiveAvatarGammaContextID"] as? String),
            "default": sanitizedConfigurationValue(infoDictionary["LiveAvatarDefaultContextID"] as? String)
                ?? defaultLiveAvatarContextID
        ].compactMapValues { $0 }
        let avatarSpeechAPIBaseURL = URL(
            string: sanitizedConfigurationValue(infoDictionary["AvatarSpeechAPIBaseURL"] as? String)
                ?? "https://api.heygen.com/v1/"
        ) ?? URL(string: "https://api.heygen.com/v1/")!
        let avatarSpeechTaskPath = sanitizedConfigurationValue(infoDictionary["AvatarSpeechTaskPath"] as? String)
            ?? "streaming.task"

        return AppEnvironment(
            backendBaseURL: backendBaseURL,
            liveAvatarAPIBaseURL: liveAvatarBaseURL,
            liveAvatarAPIKey: liveAvatarAPIKey,
            liveAvatarContextIDs: liveAvatarContextIDs,
            avatarSpeechAPIBaseURL: avatarSpeechAPIBaseURL,
            avatarSpeechTaskPath: avatarSpeechTaskPath
        )
    }

    private static func sanitizedConfigurationValue(_ value: String?) -> String? {
        guard let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        let normalized = rawValue.lowercased()
        if normalized.hasPrefix("paste-") || rawValue.hasPrefix("$(") {
            return nil
        }

        return rawValue
    }

    func liveAvatarContextID(for doctorID: String) -> String? {
        liveAvatarContextIDs[doctorID] ?? liveAvatarContextIDs["default"]
    }
}
