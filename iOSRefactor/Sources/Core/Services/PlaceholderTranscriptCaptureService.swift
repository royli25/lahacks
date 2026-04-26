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
        throw ServiceError.unsupported("Local Whisper is disabled for this HeyGen-only test build.")
    }

    func preloadGemma(onProgress: @escaping (Double) -> Void) async throws {
        throw ServiceError.unsupported("Local Gemma is disabled for this HeyGen-only test build.")
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        throw ServiceError.unsupported("Local Whisper is disabled for this HeyGen-only test build.")
    }

    func cleanTranscript(rawText: String, patientContext: String) async throws -> String {
        rawText
    }

    func generateDoctorReply(transcript: String, patientContext: String) async throws -> String {
        throw ServiceError.unsupported("Local Gemma is disabled for this HeyGen-only test build.")
    }

    func summarizeTranscript(transcript: String, doctorName: String, patientName: String) async throws -> SummaryResponse {
        throw ServiceError.unsupported("Local Gemma is disabled for this HeyGen-only test build.")
    }

    func release() async {}
}
