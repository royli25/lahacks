import XCTest
@testable import AmiyaHealthiOS

@MainActor
final class CheckupViewModelTests: XCTestCase {
    func testStartVisitStoresSessionAndGreeting() async {
        let backend = BackendServiceSpy()
        let liveAvatar = LiveAvatarServiceMock()
        liveAvatar.startSessionResult = LiveAvatarSessionPayload(
            sessionID: "session-123",
            sessionToken: "token-123",
            livekitURL: "wss://example.livekit.cloud",
            livekitClientToken: "client-token",
            maxSessionDuration: 600,
            avatarID: "avatar",
            voiceID: "voice"
        )

        let viewModel = CheckupViewModel(
            uid: "ABC123",
            patientName: "Amiya",
            doctor: DoctorDirectory.profiles[0],
            backendService: backend,
            liveAvatarService: liveAvatar,
            localVisitAIService: LocalVisitAIServiceMock(),
            transcriptCaptureService: TranscriptCaptureServiceMock()
        )

        await viewModel.startVisit()

        XCTAssertEqual(viewModel.uiState.session?.sessionID, "session-123")
        XCTAssertNil(viewModel.uiState.errorMessage)
        XCTAssertEqual(viewModel.transcript.last?.speaker, "Doctor")
    }

    func testRequestSummaryUsesISO8601TimestampsAndDefaultsNextSteps() async {
        let backend = BackendServiceSpy()
        backend.summaryResponse = SummaryResponse(summary: "Hydrate and rest")

        let viewModel = CheckupViewModel(
            uid: "ABC123",
            patientName: "Amiya",
            doctor: DoctorDirectory.profiles[0],
            backendService: backend,
            liveAvatarService: LiveAvatarServiceMock(),
            localVisitAIService: LocalVisitAIServiceMock(),
            transcriptCaptureService: TranscriptCaptureServiceMock()
        )

        viewModel.appendTranscript(speaker: "Patient", text: "I feel tired.")
        await viewModel.requestSummary()

        XCTAssertEqual(viewModel.uiState.summaryText, "Hydrate and rest")
        XCTAssertEqual(viewModel.uiState.nextSteps, [])
        XCTAssertNotNil(backend.lastSummaryRequest)
        XCTAssertTrue(backend.lastSummaryRequest?.startTime.contains("T") == true)
        XCTAssertTrue(backend.lastSummaryRequest?.currentTime.contains("T") == true)
    }
}

private final class BackendServiceSpy: BackendServiceProtocol {
    var registerPatientResult = PatientResponse(
        uid: "ABC123",
        name: "Amiya",
        phoneNumber: "+15555555555",
        agentName: "Dr. Carol Lee",
        message: "ok"
    )
    var patientLookupResult = PatientLookupResponse(name: "Amiya", doctor: "Carol")
    var summaryResponse = SummaryResponse(summary: "ok", nextSteps: [])
    var lastSummaryRequest: TranscriptSummaryRequest?

    func registerPatient(request: NewPatientRequest) async throws -> PatientResponse {
        registerPatientResult
    }

    func fetchPatient(uid: String) async throws -> PatientLookupResponse {
        patientLookupResult
    }

    func summarizeTranscript(request: TranscriptSummaryRequest) async throws -> SummaryResponse {
        lastSummaryRequest = request
        return summaryResponse
    }
}

private final class LiveAvatarServiceMock: LiveAvatarSessionServiceProtocol {
    var startSessionResult = LiveAvatarSessionPayload(
        sessionID: nil,
        sessionToken: "",
        livekitURL: nil,
        livekitClientToken: nil,
        maxSessionDuration: 0,
        avatarID: nil,
        voiceID: nil
    )

    func startSession(patientName: String, doctorID: String) async throws -> LiveAvatarSessionPayload {
        startSessionResult
    }

    func stopSession(sessionID: String?) async throws {}

    func speak(text: String, in session: LiveAvatarSessionPayload, taskType: AvatarSpeechTaskType) async throws {}
}

private struct TranscriptCaptureServiceMock: TranscriptCaptureServiceProtocol {
    func requestPermissions() async throws {}
    func beginCapture(onAudioChunk: @escaping ([Float]) async -> Void) async throws {}
    func stopCapture() {}
}

private struct LocalVisitAIServiceMock: LocalVisitAIServiceProtocol {
    func preloadWhisper(onProgress: @escaping (Double) -> Void) async throws {
        onProgress(1)
    }

    func preloadGemma(onProgress: @escaping (Double) -> Void) async throws {
        onProgress(1)
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        "I feel tired."
    }

    func cleanTranscript(rawText: String, patientContext: String) async throws -> String {
        rawText
    }

    func generateDoctorReply(transcript: String, patientContext: String) async throws -> String {
        "How long has that been happening?"
    }

    func summarizeTranscript(transcript: String, doctorName: String, patientName: String) async throws -> SummaryResponse {
        SummaryResponse(summary: "Local summary", nextSteps: ["Rest"])
    }

    func release() async {}
}
