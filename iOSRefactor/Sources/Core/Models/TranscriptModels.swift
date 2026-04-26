import Foundation

struct TranscriptEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let speaker: String
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), speaker: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}

struct TranscriptSummaryRequest: Codable, Hashable {
    let transcript: String
    let startTime: String
    let currentTime: String
    let phoneNumber: String
    let uid: String
    let doctorName: String
    let userName: String

    enum CodingKeys: String, CodingKey {
        case transcript
        case startTime = "start_time"
        case currentTime = "current_time"
        case phoneNumber = "phone_number"
        case uid
        case doctorName = "doctor_name"
        case userName = "user_name"
    }
}

struct SummaryResponse: Codable, Hashable {
    let summary: String
    let nextSteps: [String]

    init(summary: String, nextSteps: [String] = []) {
        self.summary = summary
        self.nextSteps = nextSteps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = try container.decode(String.self, forKey: .summary)
        nextSteps = try container.decodeIfPresent([String].self, forKey: .nextSteps) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case summary
        case nextSteps = "next_steps"
    }
}

struct CheckupRecord: Identifiable, Hashable {
    let id: String
    let date: String
    let duration: String
    let status: String
    let doctorName: String
    let summary: String
    let transcript: [TranscriptEntry]
    let nextSteps: [String]
}
