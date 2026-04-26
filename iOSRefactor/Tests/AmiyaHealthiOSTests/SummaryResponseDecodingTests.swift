import XCTest
@testable import AmiyaHealthiOS

final class SummaryResponseDecodingTests: XCTestCase {
    func testDecodesMissingNextStepsAsEmptyArray() throws {
        let data = Data(#"{"summary":"Follow up in two weeks."}"#.utf8)

        let response = try JSONDecoder().decode(SummaryResponse.self, from: data)

        XCTAssertEqual(response.summary, "Follow up in two weeks.")
        XCTAssertEqual(response.nextSteps, [])
    }

    func testDecodesNextStepsWhenPresent() throws {
        let data = Data(#"{"summary":"Hydrate more.","next_steps":["Drink water","Rest"]}"#.utf8)

        let response = try JSONDecoder().decode(SummaryResponse.self, from: data)

        XCTAssertEqual(response.summary, "Hydrate more.")
        XCTAssertEqual(response.nextSteps, ["Drink water", "Rest"])
    }

    func testLiveAvatarTokenRequestEncodesFullModeAndContext() throws {
        let request = LiveAvatarTokenRequest(
            avatarID: "avatar-123",
            avatarPersona: LiveAvatarPersonaRequest(
                voiceID: "voice-123",
                contextID: "context-123",
                language: "en"
            )
        )

        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let persona = try XCTUnwrap(object["avatar_persona"] as? [String: Any])

        XCTAssertEqual(object["mode"] as? String, "FULL")
        XCTAssertEqual(object["avatar_id"] as? String, "avatar-123")
        XCTAssertEqual(persona["voice_id"] as? String, "voice-123")
        XCTAssertEqual(persona["context_id"] as? String, "context-123")
        XCTAssertEqual(persona["language"] as? String, "en")
    }
}
