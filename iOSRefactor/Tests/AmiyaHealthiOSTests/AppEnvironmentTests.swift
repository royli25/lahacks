import XCTest
@testable import AmiyaHealthiOS

final class AppEnvironmentTests: XCTestCase {
    func testFallsBackWhenBuildSettingsAreUnresolved() {
        let environment = AppEnvironment.current(infoDictionary: [
            "BackendBaseURL": "$(BACKEND_BASE_URL)",
            "LiveAvatarAPIBaseURL": "$(LIVEAVATAR_API_BASE_URL)",
            "LiveAvatarAPIKey": "paste-liveavatar-key-here",
            "LiveAvatarDefaultContextID": "$(LIVEAVATAR_DEFAULT_CONTEXT_ID)",
            "LiveAvatarAlphaContextID": "$(LIVEAVATAR_ALPHA_CONTEXT_ID)",
            "LiveAvatarBetaContextID": "$(LIVEAVATAR_BETA_CONTEXT_ID)",
            "LiveAvatarGammaContextID": "$(LIVEAVATAR_GAMMA_CONTEXT_ID)",
            "AvatarSpeechAPIBaseURL": "$(AVATAR_SPEECH_API_BASE_URL)",
            "AvatarSpeechTaskPath": "$(AVATAR_SPEECH_TASK_PATH)",
            "ZeticPersonalKey": "paste-zetic-personal-key-here",
            "ZeticWhisperEncoderModel": "$(ZETIC_WHISPER_ENCODER_MODEL)",
            "ZeticWhisperDecoderModel": "$(ZETIC_WHISPER_DECODER_MODEL)",
            "ZeticGemmaModel": "$(ZETIC_GEMMA_MODEL)",
            "ZeticModelVersion": "$(ZETIC_MODEL_VERSION)"
        ])

        XCTAssertEqual(environment.backendBaseURL.absoluteString, "http://127.0.0.1:8000/")
        XCTAssertEqual(environment.liveAvatarAPIBaseURL.absoluteString, "https://api.liveavatar.com/v1/")
        XCTAssertEqual(environment.liveAvatarAPIKey, "")
        XCTAssertEqual(environment.liveAvatarContextID(for: "alpha"), "567e8371-f69f-49ec-9f2d-054083431165")
        XCTAssertEqual(environment.avatarSpeechAPIBaseURL.absoluteString, "https://api.heygen.com/v1/")
        XCTAssertEqual(environment.avatarSpeechTaskPath, "streaming.task")
        XCTAssertEqual(environment.zeticConfiguration.personalKey, "")
        XCTAssertEqual(environment.zeticConfiguration.whisperEncoderModelName, "OpenAI/whisper-tiny-encoder")
        XCTAssertEqual(environment.zeticConfiguration.whisperDecoderModelName, "OpenAI/whisper-tiny-decoder")
        XCTAssertEqual(environment.zeticConfiguration.gemmaModelName, "changgeun/gemma-4-E2B-it")
        XCTAssertEqual(environment.zeticConfiguration.modelVersion, 1)
    }

    func testResolvesDoctorSpecificLiveAvatarContextID() {
        let environment = AppEnvironment.current(infoDictionary: [
            "LiveAvatarAlphaContextID": "context-alpha",
            "LiveAvatarDefaultContextID": "context-default"
        ])

        XCTAssertEqual(environment.liveAvatarContextID(for: "alpha"), "context-alpha")
        XCTAssertEqual(environment.liveAvatarContextID(for: "beta"), "context-default")
    }
}
