import Foundation

struct NewPatientRequest: Codable, Hashable {
    let name: String
    let phoneNumber: String
    let agentName: String

    enum CodingKeys: String, CodingKey {
        case name
        case phoneNumber = "phone_number"
        case agentName = "agent_name"
    }
}

struct PatientResponse: Codable, Hashable {
    let uid: String
    let name: String
    let phoneNumber: String
    let agentName: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case phoneNumber = "phone_number"
        case agentName = "agent_name"
        case message
    }
}

struct PatientLookupResponse: Codable, Hashable {
    let name: String
    let doctor: String
}

