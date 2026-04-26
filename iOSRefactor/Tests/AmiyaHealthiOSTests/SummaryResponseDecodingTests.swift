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
}
