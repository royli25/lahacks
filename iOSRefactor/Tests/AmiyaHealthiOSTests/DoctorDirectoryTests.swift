import XCTest
@testable import AmiyaHealthiOS

final class DoctorDirectoryTests: XCTestCase {
    func testResolvesDoctorByFullAgentName() {
        let doctor = DoctorDirectory.resolveProfile(for: "Dr. Karen Roberts")

        XCTAssertEqual(doctor?.id, "gamma")
    }

    func testResolvesDoctorByFirstNameStoredInBackend() {
        let doctor = DoctorDirectory.resolveProfile(for: "Karen")

        XCTAssertEqual(doctor?.id, "gamma")
    }

    func testResolvesDoctorByProfileID() {
        let doctor = DoctorDirectory.resolveProfile(for: "beta")

        XCTAssertEqual(doctor?.agentName, "Dr. Dexter Sins")
    }
}
