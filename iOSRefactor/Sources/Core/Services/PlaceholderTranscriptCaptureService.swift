import Foundation

struct PlaceholderTranscriptCaptureService: TranscriptCaptureServiceProtocol {
    func requestPermissions() async throws {
        throw ServiceError.unsupported(
            "Transcript capture is still a placeholder in the Swift refactor. Wire Apple Speech or a backend STT service next."
        )
    }

    func beginCapture() async throws {
        throw ServiceError.unsupported(
            "Transcript capture is not implemented yet in the Swift refactor."
        )
    }

    func stopCapture() {}
}

