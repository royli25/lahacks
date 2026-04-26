import Foundation

struct CheckupUIState {
    var statusMessage = "Ready to start visit"
    var session: LiveAvatarSessionPayload?
    var errorMessage: String?
    var isStartingSession = false
    var isMuted = false
    var summaryText = ""
    var nextSteps: [String] = []
}

@MainActor
final class CheckupViewModel: ObservableObject {
    @Published private(set) var uiState = CheckupUIState()
    @Published private(set) var transcript: [TranscriptEntry] = []

    let uid: String
    let patientName: String
    let doctor: DoctorProfile

    private let backendService: any BackendServiceProtocol
    private let liveAvatarService: any LiveAvatarSessionServiceProtocol
    private let transcriptCaptureService: any TranscriptCaptureServiceProtocol
    private let startTime = Date()
    private let timestampFormatter = ISO8601DateFormatter()

    init(
        uid: String,
        patientName: String,
        doctor: DoctorProfile,
        backendService: any BackendServiceProtocol,
        liveAvatarService: any LiveAvatarSessionServiceProtocol,
        transcriptCaptureService: any TranscriptCaptureServiceProtocol = PlaceholderTranscriptCaptureService()
    ) {
        self.uid = uid
        self.patientName = patientName
        self.doctor = doctor
        self.backendService = backendService
        self.liveAvatarService = liveAvatarService
        self.transcriptCaptureService = transcriptCaptureService
        self.timestampFormatter.formatOptions = [.withInternetDateTime]
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
            uiState.statusMessage = "Session started. Wire native LiveKit rendering next."
            appendTranscript(speaker: "Doctor", text: "Hi, \(patientName)!")
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

    func appendTranscript(speaker: String, text: String) {
        transcript.append(TranscriptEntry(speaker: speaker, text: text))
    }

    func requestTranscriptCapture() async {
        do {
            try await transcriptCaptureService.requestPermissions()
            uiState.statusMessage = "Transcript capture permissions granted. Integrate Apple Speech next."
        } catch {
            uiState.errorMessage = error.localizedDescription
        }
    }

    func requestSummary() async {
        let transcriptText = transcript
            .map { "\($0.speaker): \($0.text)" }
            .joined(separator: "\n")

        guard !transcriptText.isEmpty else {
            uiState.errorMessage = "Transcript is empty. Capture or append transcript data before summarizing."
            return
        }

        uiState.errorMessage = nil
        uiState.statusMessage = "Generating summary..."

        do {
            let response = try await backendService.summarizeTranscript(
                request: TranscriptSummaryRequest(
                    transcript: transcriptText,
                    startTime: timestampFormatter.string(from: startTime),
                    currentTime: timestampFormatter.string(from: Date()),
                    phoneNumber: "",
                    uid: uid,
                    doctorName: doctor.agentName,
                    userName: patientName
                )
            )

            uiState.summaryText = response.summary
            uiState.nextSteps = response.nextSteps
            uiState.statusMessage = "Summary ready"
        } catch {
            uiState.errorMessage = error.localizedDescription
            uiState.statusMessage = "Summary failed"
        }
    }
}
