import AVFoundation
import Foundation

final class AudioChunkTranscriptCaptureService: TranscriptCaptureServiceProtocol {
    private let sampleRate: Double = 16_000
    private let chunkDuration: TimeInterval = 5
    private let lock = NSLock()

    private var audioEngine: AVAudioEngine?
    private var bufferedSamples: [Float] = []
    private var onAudioChunk: (([Float]) async -> Void)?

    func requestPermissions() async throws {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        if !granted {
            throw ServiceError.unsupported("Microphone permission is required for local Zetic transcription.")
        }
    }

    func beginCapture(onAudioChunk: @escaping ([Float]) async -> Void) async throws {
        stopCapture()
        try await requestPermissions()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ),
        let converter = AVAudioConverter(from: hardwareFormat, to: targetFormat) else {
            throw ServiceError.unsupported("Unable to configure 16 kHz microphone capture for Whisper.")
        }

        self.audioEngine = engine
        self.onAudioChunk = onAudioChunk
        lock.locked {
            bufferedSamples.removeAll(keepingCapacity: true)
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: hardwareFormat) { [weak self] buffer, _ in
            self?.handleInputBuffer(buffer, converter: converter, targetFormat: targetFormat)
        }

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
            self.onAudioChunk = nil
            throw error
        }
    }

    func stopCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        onAudioChunk = nil

        lock.locked {
            bufferedSamples.removeAll(keepingCapacity: true)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handleInputBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) {
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let targetFrameCapacity = max(1, AVAudioFrameCount(Double(buffer.frameLength) * ratio))

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: targetFrameCapacity
        ) else {
            return
        }

        var conversionError: NSError?
        var didProvideInput = false
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }

            didProvideInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: convertedBuffer, error: &conversionError, withInputFrom: inputBlock)
        guard conversionError == nil, let channel = convertedBuffer.floatChannelData?[0] else {
            return
        }

        let samples = Array(UnsafeBufferPointer(start: channel, count: Int(convertedBuffer.frameLength)))
        let chunks = appendAndDrainChunks(samples)

        guard let onAudioChunk else {
            return
        }

        for chunk in chunks {
            Task {
                await onAudioChunk(chunk)
            }
        }
    }

    private func appendAndDrainChunks(_ samples: [Float]) -> [[Float]] {
        let chunkSize = Int(sampleRate * chunkDuration)

        return lock.locked {
            bufferedSamples.append(contentsOf: samples)

            var chunks: [[Float]] = []
            while bufferedSamples.count >= chunkSize {
                chunks.append(Array(bufferedSamples.prefix(chunkSize)))
                bufferedSamples.removeFirst(chunkSize)
            }

            return chunks
        }
    }
}

private extension NSLock {
    func locked<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
