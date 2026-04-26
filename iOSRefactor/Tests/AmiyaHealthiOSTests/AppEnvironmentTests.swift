import XCTest
@testable import AmiyaHealthiOS

final class AppEnvironmentTests: XCTestCase {
    func testFallsBackWhenBuildSettingsAreUnresolved() {
        let environment = AppEnvironment.current(infoDictionary: [
            "BackendBaseURL": "$(BACKEND_BASE_URL)",
            "LiveAvatarAPIBaseURL": "$(LIVEAVATAR_API_BASE_URL)",
            "LiveAvatarAPIKey": "paste-liveavatar-key-here",
            "LiveAvatarAlphaContextID": "$(LIVEAVATAR_ALPHA_CONTEXT_ID)",
            "LiveAvatarBetaContextID": "$(LIVEAVATAR_BETA_CONTEXT_ID)",
            "LiveAvatarGammaContextID": "$(LIVEAVATAR_GAMMA_CONTEXT_ID)",
            "AvatarSpeechAPIBaseURL": "$(AVATAR_SPEECH_API_BASE_URL)",
            "AvatarSpeechTaskPath": "$(AVATAR_SPEECH_TASK_PATH)"
        ])

        XCTAssertEqual(environment.backendBaseURL.absoluteString, "http://127.0.0.1:8000/")
        XCTAssertEqual(environment.liveAvatarAPIBaseURL.absoluteString, "https://api.liveavatar.com/v1/")
        XCTAssertEqual(environment.liveAvatarAPIKey, "")
        XCTAssertNil(environment.liveAvatarContextID(for: "alpha"))
        XCTAssertEqual(environment.avatarSpeechAPIBaseURL.absoluteString, "https://api.heygen.com/v1/")
        XCTAssertEqual(environment.avatarSpeechTaskPath, "streaming.task")
    }

    func testResolvesDoctorSpecificLiveAvatarContextID() {
        let environment = AppEnvironment.current(infoDictionary: [
            "LiveAvatarAlphaContextID": "context-alpha"
        ])

        XCTAssertEqual(environment.liveAvatarContextID(for: "alpha"), "context-alpha")
        XCTAssertNil(environment.liveAvatarContextID(for: "beta"))
    }
}
