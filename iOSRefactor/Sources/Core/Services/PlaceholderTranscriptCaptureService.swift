import Foundation

struct PlaceholderTranscriptCaptureService: TranscriptCaptureServiceProtocol {
    func requestPermissions() async throws {
        throw ServiceError.unsupported(
            "Transcript capture is still a placeholder in this test configuration."
        )
    }

    func beginCapture(onAudioChunk: @escaping ([Float]) async -> Void) async throws {
        throw ServiceError.unsupported(
            "Transcript capture is not implemented in this test configuration."
        )
    }

    func stopCapture() {}
}

struct DisabledLocalVisitAIService: LocalVisitAIServiceProtocol {
    func preloadWhisper(onProgress: @escaping (Double) -> Void) async throws {
        throw ServiceError.unsupported("Local Zetic Whisper is not configured for this build.")
    }

    func preloadGemma(onProgress: @escaping (Double) -> Void) async throws {
        throw ServiceError.unsupported("Local Zetic Gemma is not configured for this build.")
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        throw ServiceError.unsupported("Local Zetic Whisper is not configured for this build.")
    }

    func cleanTranscript(rawText: String, patientContext: String) async throws -> String {
        rawText
    }

    func generateDoctorReply(transcript: String, patientContext: String) async throws -> String {
        throw ServiceError.unsupported("Local Zetic Gemma is not configured for this build.")
    }

    func summarizeTranscript(transcript: String, doctorName: String, patientName: String) async throws -> SummaryResponse {
        throw ServiceError.unsupported("Local Zetic Gemma is not configured for this build.")
    }

    func release() async {}
}
