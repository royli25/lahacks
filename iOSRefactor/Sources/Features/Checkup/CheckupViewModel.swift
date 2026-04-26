import Foundation

struct CheckupUIState {
    var statusMessage = "Ready to start visit"
    var session: LiveAvatarSessionPayload?
    var errorMessage: String?
    var isStartingSession = false
    var isMuted = false
}

@MainActor
final class CheckupViewModel: ObservableObject {
    @Published private(set) var uiState = CheckupUIState()

    let patientName: String
    let doctor: DoctorProfile

    private let liveAvatarService: any LiveAvatarSessionServiceProtocol

    init(
        patientName: String,
        doctor: DoctorProfile,
        liveAvatarService: any LiveAvatarSessionServiceProtocol
    ) {
        self.patientName = patientName
        self.doctor = doctor
        self.liveAvatarService = liveAvatarService
    }

    func startVisit() async {
        guard !uiState.isStartingSession else { return }

        uiState.isStartingSession = true
        uiState.errorMessage = nil
        uiState.statusMessage = "Starting paid session..."

        defer { uiState.isStartingSession = false }

        do {
            let session = try await liveAvatarService.startSession(
                patientName: patientName,
                doctorID: doctor.id
            )
            uiState.session = session
            uiState.statusMessage = "Session ready. Speak to the avatar."
        } catch {
            uiState.errorMessage = error.localizedDescription
            uiState.statusMessage = "Unable to connect to doctor"
        }
    }

    func endVisit() async {
        uiState.errorMessage = nil

        do {
            try await liveAvatarService.stopSession(sessionID: uiState.session?.sessionID)
            uiState.session = nil
            uiState.statusMessage = "Session stopped"
        } catch {
            uiState.errorMessage = error.localizedDescription
        }
    }

    func toggleMute() {
        uiState.isMuted.toggle()
    }
}
