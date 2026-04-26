import Foundation

struct AppEnvironment {
    let backendBaseURL: URL
    let liveAvatarAPIBaseURL: URL
    let liveAvatarAPIKey: String

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

        return AppEnvironment(
            backendBaseURL: backendBaseURL,
            liveAvatarAPIBaseURL: liveAvatarBaseURL,
            liveAvatarAPIKey: liveAvatarAPIKey
        )
    }

    private static func sanitizedConfigurationValue(_ value: String?) -> String? {
        guard let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        let normalized = rawValue.lowercased()
        if normalized == "paste-liveavatar-key-here" || rawValue.hasPrefix("$(") {
            return nil
        }

        return rawValue
    }
}
