import XCTest
@testable import AmiyaHealthiOS

final class AppEnvironmentTests: XCTestCase {
    func testFallsBackWhenBuildSettingsAreUnresolved() {
        let environment = AppEnvironment.current(infoDictionary: [
            "BackendBaseURL": "$(BACKEND_BASE_URL)",
            "LiveAvatarAPIBaseURL": "$(LIVEAVATAR_API_BASE_URL)",
            "LiveAvatarAPIKey": "paste-liveavatar-key-here"
        ])

        XCTAssertEqual(environment.backendBaseURL.absoluteString, "http://127.0.0.1:8000/")
        XCTAssertEqual(environment.liveAvatarAPIBaseURL.absoluteString, "https://api.liveavatar.com/v1/")
        XCTAssertEqual(environment.liveAvatarAPIKey, "")
    }
}
