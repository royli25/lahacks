import Foundation

struct AppEnvironment {
    let liveAvatarAPIBaseURL: URL
    let liveAvatarAPIKey: String

    static func current(bundle: Bundle = .main) -> AppEnvironment {
        current(infoDictionary: bundle.infoDictionary ?? [:])
    }

    static func current(infoDictionary: [String: Any]) -> AppEnvironment {
        let liveAvatarBaseURL = URL(
            string: sanitizedConfigurationValue(infoDictionary["LiveAvatarAPIBaseURL"] as? String)
                ?? "https://api.liveavatar.com/v1/"
        ) ?? URL(string: "https://api.liveavatar.com/v1/")!

        let liveAvatarAPIKey = sanitizedConfigurationValue(infoDictionary["LiveAvatarAPIKey"] as? String) ?? ""

        return AppEnvironment(
            liveAvatarAPIBaseURL: liveAvatarBaseURL,
            liveAvatarAPIKey: liveAvatarAPIKey
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
}
