import Foundation

struct AppEnvironment {
    let backendBaseURL: URL
    let liveAvatarAPIBaseURL: URL
    let liveAvatarAPIKey: String
    let avatarSpeechAPIBaseURL: URL
    let avatarSpeechTaskPath: String
    let zeticConfiguration: ZeticModelConfiguration

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
        let avatarSpeechAPIBaseURL = URL(
            string: sanitizedConfigurationValue(infoDictionary["AvatarSpeechAPIBaseURL"] as? String)
                ?? "https://api.heygen.com/v1/"
        ) ?? URL(string: "https://api.heygen.com/v1/")!
        let avatarSpeechTaskPath = sanitizedConfigurationValue(infoDictionary["AvatarSpeechTaskPath"] as? String)
            ?? "streaming.task"

        let zeticPersonalKey = sanitizedConfigurationValue(infoDictionary["ZeticPersonalKey"] as? String) ?? ""
        let zeticWhisperEncoderModel = sanitizedConfigurationValue(infoDictionary["ZeticWhisperEncoderModel"] as? String)
            ?? "OpenAI/whisper-tiny-encoder"
        let zeticWhisperDecoderModel = sanitizedConfigurationValue(infoDictionary["ZeticWhisperDecoderModel"] as? String)
            ?? "OpenAI/whisper-tiny-decoder"
        let zeticGemmaModel = sanitizedConfigurationValue(infoDictionary["ZeticGemmaModel"] as? String)
            ?? "changgeun/gemma-4-E2B-it"
        let zeticModelVersion = sanitizedIntegerValue(infoDictionary["ZeticModelVersion"] as? String) ?? 1

        return AppEnvironment(
            backendBaseURL: backendBaseURL,
            liveAvatarAPIBaseURL: liveAvatarBaseURL,
            liveAvatarAPIKey: liveAvatarAPIKey,
            avatarSpeechAPIBaseURL: avatarSpeechAPIBaseURL,
            avatarSpeechTaskPath: avatarSpeechTaskPath,
            zeticConfiguration: ZeticModelConfiguration(
                personalKey: zeticPersonalKey,
                whisperEncoderModelName: zeticWhisperEncoderModel,
                whisperDecoderModelName: zeticWhisperDecoderModel,
                gemmaModelName: zeticGemmaModel,
                modelVersion: zeticModelVersion
            )
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

    private static func sanitizedIntegerValue(_ value: String?) -> Int? {
        guard let rawValue = sanitizedConfigurationValue(value) else {
            return nil
        }

        return Int(rawValue)
    }
}

struct ZeticModelConfiguration: Hashable {
    let personalKey: String
    let whisperEncoderModelName: String
    let whisperDecoderModelName: String
    let gemmaModelName: String
    let modelVersion: Int
}
