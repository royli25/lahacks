#if canImport(ZeticMLange) && canImport(ext)
import Foundation
import ZeticMLange
import ext

actor ZeticVisitAIService: LocalVisitAIServiceProtocol {
    private enum Constants {
        static let decoderMaxLength = 448
        static let decoderPadToken = Int32(100)
        static let whisperStartToken = Int32(50_258)
        static let whisperEndToken = 50_257
    }

    private let configuration: ZeticModelConfiguration
    private let bundle: Bundle

    private var whisperEncoderModel: ZeticMLangeModel?
    private var whisperDecoderModel: ZeticMLangeModel?
    private var whisperWrapper: WhisperWrapper?
    private var gemmaModel: ZeticMLangeLLMModel?

    init(configuration: ZeticModelConfiguration, bundle: Bundle = .main) {
        self.configuration = configuration
        self.bundle = bundle
    }

    func preloadWhisper(onProgress: @escaping (Double) -> Void = { _ in }) async throws {
        try requirePersonalKey()

        if whisperWrapper == nil {
            guard let vocabPath = bundle.path(forResource: "vocab", ofType: "json") else {
                throw ServiceError.missingConfiguration("Missing Resources/vocab.json for Whisper token decoding.")
            }

            whisperWrapper = WhisperWrapper(vocabPath)
        }

        if whisperEncoderModel == nil {
            whisperEncoderModel = try ZeticMLangeModel(
                personalKey: configuration.personalKey,
                name: configuration.whisperEncoderModelName,
                version: configuration.modelVersion,
                modelMode: ModelMode.RUN_AUTO,
                onDownload: { progress in onProgress(Double(progress) * 0.45) }
            )
        }

        if whisperDecoderModel == nil {
            whisperDecoderModel = try ZeticMLangeModel(
                personalKey: configuration.personalKey,
                name: configuration.whisperDecoderModelName,
                version: configuration.modelVersion,
                modelMode: ModelMode.RUN_AUTO,
                onDownload: { progress in onProgress(0.45 + Double(progress) * 0.55) }
            )
        }

        onProgress(1)
    }

    func preloadGemma(onProgress: @escaping (Double) -> Void = { _ in }) async throws {
        try requirePersonalKey()

        guard gemmaModel == nil else {
            onProgress(1)
            return
        }

        gemmaModel = try ZeticMLangeLLMModel(
            personalKey: configuration.personalKey,
            name: configuration.gemmaModelName,
            version: configuration.modelVersion,
            modelMode: LLMModelMode.RUN_AUTO,
            onDownload: { progress in onProgress(Double(progress)) }
        )
        onProgress(1)
    }

    func transcribe(audioSamples: [Float]) async throws -> String {
        try await preloadWhisper()

        guard let whisperWrapper, let whisperEncoderModel, let whisperDecoderModel else {
            throw ServiceError.invalidResponse
        }

        let features = whisperWrapper.process(audioSamples)
        let encoderOutput = try runWhisperEncoder(model: whisperEncoderModel, features: features)
        let generatedTokenIDs = try runWhisperDecoder(model: whisperDecoderModel, encoderOutput: encoderOutput)
        return whisperWrapper.decodeToken(generatedTokenIDs, true)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanTranscript(rawText: String, patientContext: String) async throws -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        let prompt = """
        <start_of_turn>user
        You are a medical transcription assistant for a live telehealth visit.
        Clean up the speech-to-text output. Remove filler words, fix grammar, preserve the patient's meaning, and do not add facts.

        Context:
        \(patientContext)

        Raw transcription:
        \(trimmed)

        Return only the cleaned patient statement.
        <end_of_turn>
        <start_of_turn>model
        """

        return try await generate(prompt: prompt)
    }

    func generateDoctorReply(transcript: String, patientContext: String) async throws -> String {
        let prompt = """
        <start_of_turn>user
        You are the on-device reasoning layer for a telehealth doctor avatar.
        Use the context and transcript to produce the doctor's next spoken response.
        Keep the response medically cautious, concise, and conversational. Ask one focused follow-up question when more information is needed.

        Context:
        \(patientContext)

        Transcript:
        \(transcript)

        Return only the exact sentence or sentences the avatar should speak.
        <end_of_turn>
        <start_of_turn>model
        """

        return try await generate(prompt: prompt)
    }

    func summarizeTranscript(transcript: String, doctorName: String, patientName: String) async throws -> SummaryResponse {
        let prompt = """
        <start_of_turn>user
        You are a medical scribe. Summarize the following telehealth consultation between \(doctorName) and \(patientName).

        Transcript:
        \(transcript)

        Provide a response in this exact format:
        SUMMARY: [2-3 sentence clinical summary]
        NEXT_STEPS:
        - [action item 1]
        - [action item 2]
        - [action item 3]
        <end_of_turn>
        <start_of_turn>model
        """

        let output = try await generate(prompt: prompt)
        let parsed = parseStructuredSummary(output)
        return SummaryResponse(summary: parsed.summary, nextSteps: parsed.nextSteps)
    }

    func release() async {
        whisperEncoderModel = nil
        whisperDecoderModel = nil
        whisperWrapper = nil
        gemmaModel = nil
    }

    private func generate(prompt: String) async throws -> String {
        try await preloadGemma()

        guard let gemmaModel else {
            throw ServiceError.invalidResponse
        }

        try gemmaModel.run(prompt)

        var buffer = ""
        while true {
            let result = gemmaModel.waitForNextToken()
            if result.generatedTokens == 0 {
                break
            }

            if !result.token.isEmpty {
                buffer.append(result.token)
            }
        }

        return buffer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runWhisperEncoder(model: ZeticMLangeModel, features: [Float]) throws -> Data {
        let data = features.withUnsafeBufferPointer { buffer -> Data in
            guard let baseAddress = buffer.baseAddress else {
                return Data()
            }

            return Data(bytes: baseAddress, count: buffer.count * MemoryLayout<Float>.size)
        }

        let tensor = Tensor(data: data, dataType: BuiltinDataType.int8, shape: [data.count])
        let outputs = try model.run(inputs: [tensor])
        return outputs[0].data
    }

    private func runWhisperDecoder(model: ZeticMLangeModel, encoderOutput: Data) throws -> [Int32] {
        var decoderTokenIDs = Array(repeating: Constants.decoderPadToken, count: Constants.decoderMaxLength)
        var decoderAttentionMask = Array(repeating: Int32(0), count: Constants.decoderMaxLength)
        var generatedTokenIDs: [Int32] = []

        decoderTokenIDs[0] = Constants.whisperStartToken
        decoderAttentionMask[0] = 1

        for index in 0..<Constants.decoderMaxLength {
            let logits = try decodeStep(
                model: model,
                decoderTokenIDs: decoderTokenIDs,
                encoderOutput: encoderOutput,
                decoderAttentionMask: decoderAttentionMask
            )

            let vocabSize = logits.count / Constants.decoderMaxLength
            guard vocabSize > 0 else {
                break
            }

            let startIndex = vocabSize * index
            let endIndex = min(startIndex + vocabSize, logits.count)
            guard startIndex < endIndex else {
                break
            }

            let nextToken = argmax(Array(logits[startIndex..<endIndex]))
            if nextToken == Constants.whisperEndToken {
                break
            }

            generatedTokenIDs.append(Int32(nextToken))

            if index + 1 < Constants.decoderMaxLength {
                decoderTokenIDs[index + 1] = Int32(nextToken)
                decoderAttentionMask[index + 1] = 1
            }
        }

        return generatedTokenIDs
    }

    private func decodeStep(
        model: ZeticMLangeModel,
        decoderTokenIDs: [Int32],
        encoderOutput: Data,
        decoderAttentionMask: [Int32]
    ) throws -> [Float] {
        let decoderTokenData = littleEndianData(from: decoderTokenIDs)
        let attentionMaskData = littleEndianData(from: decoderAttentionMask)

        _ = try model.run(inputs: [
            Tensor(data: decoderTokenData, dataType: BuiltinDataType.int8, shape: [decoderTokenData.count]),
            Tensor(data: encoderOutput, dataType: BuiltinDataType.int8, shape: [encoderOutput.count]),
            Tensor(data: attentionMaskData, dataType: BuiltinDataType.int8, shape: [attentionMaskData.count])
        ])

        guard let outputData = model.getOutputDataArray().first else {
            return []
        }

        return floatArray(from: outputData)
    }

    private func littleEndianData(from values: [Int32]) -> Data {
        var data = Data()
        data.reserveCapacity(values.count * MemoryLayout<Int32>.size)

        for value in values {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }

    private func floatArray(from data: Data) -> [Float] {
        data.withUnsafeBytes { rawBuffer in
            rawBuffer.bindMemory(to: UInt32.self).map { word in
                Float(bitPattern: UInt32(littleEndian: word))
            }
        }
    }

    private func argmax(_ values: [Float]) -> Int {
        values.indices.max { values[$0] < values[$1] } ?? 0
    }

    private func parseStructuredSummary(_ output: String) -> (summary: String, nextSteps: [String]) {
        let components = output.components(separatedBy: "NEXT_STEPS:")
        let summary = components.first?
            .replacingOccurrences(of: "SUMMARY:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? output

        let nextSteps = components.dropFirst().first?
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
            ?? []

        return (summary, nextSteps)
    }

    private func requirePersonalKey() throws {
        guard !configuration.personalKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.missingConfiguration("Missing Zetic personal key. Fill ZETIC_PERSONAL_KEY in Config/Secrets.xcconfig.")
        }
    }
}

#else
import Foundation

actor ZeticVisitAIService: LocalVisitAIServiceProtocol {
    private let configuration: ZeticModelConfiguration
    init(configuration: ZeticModelConfiguration, bundle: Bundle = .main) {
        self.configuration = configuration
    }

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
#endif
