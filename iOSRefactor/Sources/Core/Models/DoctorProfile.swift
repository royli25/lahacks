import Foundation

struct DoctorProfile: Identifiable, Codable, Hashable {
    let id: String
    let agentName: String
    let avatarID: String
    let displayName: String
    let specialty: String

    enum CodingKeys: String, CodingKey {
        case id
        case agentName = "agent_name"
        case avatarID = "avatar_id"
        case displayName
        case specialty
    }
}

struct LiveAvatarDoctorConfig: Hashable {
    let avatarID: String
    let voiceID: String
}

enum DoctorDirectory {
    static let profiles: [DoctorProfile] = [
        DoctorProfile(
            id: "alpha",
            agentName: "Dr. Carol Lee",
            avatarID: "alpha_avatar",
            displayName: "Dr. Carol Lee",
            specialty: "Internal Medicine"
        ),
        DoctorProfile(
            id: "beta",
            agentName: "Dr. Dexter Sins",
            avatarID: "beta_avatar",
            displayName: "Dr. Dexter Sins",
            specialty: "Family Medicine"
        ),
        DoctorProfile(
            id: "gamma",
            agentName: "Dr. Karen Roberts",
            avatarID: "gamma_avatar",
            displayName: "Dr. Karen Roberts",
            specialty: "Geriatrics"
        )
    ]

    static func liveAvatarConfig(for doctorID: String) -> LiveAvatarDoctorConfig {
        switch doctorID {
        case "alpha":
            return LiveAvatarDoctorConfig(
                avatarID: "567e8371-f69f-49ec-9f2d-054083431165",
                voiceID: "de5574fc-009e-4a01-a881-9919ef8f5a0c"
            )
        case "beta":
            return LiveAvatarDoctorConfig(
                avatarID: "bd43ce31-7425-4379-8407-60f029548e61",
                voiceID: "b952f553-f7f3-4e52-8625-86b4c415384f"
            )
        default:
            return LiveAvatarDoctorConfig(
                avatarID: "07faa1c4-b7e1-4d26-a38a-337364dee160",
                voiceID: "4f3b1e99-b580-4f05-9b67-a5f585be0232"
            )
        }
    }

    static func resolveProfile(for rawDoctorValue: String) -> DoctorProfile? {
        let normalized = rawDoctorValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalized.isEmpty else {
            return nil
        }

        return profiles.first { profile in
            profile.id.lowercased() == normalized
                || profile.agentName.lowercased() == normalized
                || profile.displayName.lowercased() == normalized
                || profile.agentName
                    .replacingOccurrences(of: "Dr. ", with: "")
                    .split(separator: " ")
                    .first?
                    .lowercased() == normalized
        }
    }
}
