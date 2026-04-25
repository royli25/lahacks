package com.amiya.health.ml

import android.content.Context
import com.zeticai.mlange.core.model.llm.ZeticMLangeLLMModel
import com.zeticai.mlange.core.model.llm.LLMModelMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext

class GemmaManager(private val context: Context) {

    private var model: ZeticMLangeLLMModel? = null

    private val ZETIC_API_KEY = "dev_66cf3a5ebcfb48179b4c61b89f96d6ce"

    suspend fun initialize(onProgress: (Float) -> Unit = {}) {
        withContext(Dispatchers.IO) {
            model = ZeticMLangeLLMModel(
                context,
                ZETIC_API_KEY,
                "changgeun/gemma-4-E2B-it",
                version = 1,
                modelMode = LLMModelMode.RUN_AUTO,
                onProgress = { onProgress(it) }
            )
        }
    }

    suspend fun generate(prompt: String): String = withContext(Dispatchers.IO) {
        val llm = model ?: return@withContext ""

        llm.run(prompt)

        val sb = StringBuilder()
        while (true) {
            val waitResult = llm.waitForNextToken()
            val token = waitResult.token
            val generatedTokens = waitResult.generatedTokens

            if (generatedTokens == 0) break
            if (token.isNotEmpty()) sb.append(token)
        }

        sb.toString().trim()
    }

    fun generateStream(prompt: String): Flow<String> = flow {
        val llm = model ?: return@flow

        withContext(Dispatchers.IO) {
            llm.run(prompt)
        }

        while (true) {
            val waitResult = withContext(Dispatchers.IO) { llm.waitForNextToken() }
            val token = waitResult.token
            val generatedTokens = waitResult.generatedTokens

            if (generatedTokens == 0) break
            if (token.isNotEmpty()) emit(token)
        }
    }

    suspend fun processTranscript(
        transcript: String,
        doctorName: String,
        patientName: String
    ): Pair<String, List<String>> {
        val prompt = buildSummarizationPrompt(transcript, doctorName, patientName)
        val output = generate(prompt)
        return parseStructuredOutput(output)
    }

    suspend fun processAudioText(rawText: String, patientContext: String): String {
        val prompt = buildCleanupPrompt(rawText, patientContext)
        return generate(prompt)
    }

    private fun buildSummarizationPrompt(
        transcript: String,
        doctorName: String,
        patientName: String
    ): String = """<start_of_turn>user
You are a medical scribe. Summarize the following telehealth consultation between $doctorName and $patientName.

Transcript:
$transcript

Provide a response in this exact format:
SUMMARY: [2-3 sentence clinical summary]
NEXT_STEPS:
- [action item 1]
- [action item 2]
- [action item 3]
<end_of_turn>
<start_of_turn>model
"""

    private fun buildCleanupPrompt(rawText: String, patientContext: String): String = """<start_of_turn>user
You are a medical transcription assistant. Clean up the following speech-to-text output from a patient during a telehealth visit. Remove filler words, fix grammar, and ensure medical terms are correct. Keep the meaning intact.

Patient context: $patientContext

Raw transcription: $rawText

Return only the cleaned text, nothing else.
<end_of_turn>
<start_of_turn>model
"""

    private fun parseStructuredOutput(output: String): Pair<String, List<String>> {
        val summaryRegex = Regex("SUMMARY:\\s*(.+?)(?=NEXT_STEPS:|$)", RegexOption.DOT_MATCHES_ALL)
        val summaryMatch = summaryRegex.find(output)
        val summary = summaryMatch?.groupValues?.get(1)?.trim() ?: output

        val nextStepsRegex = Regex("NEXT_STEPS:\\s*(.+)", RegexOption.DOT_MATCHES_ALL)
        val nextStepsMatch = nextStepsRegex.find(output)
        val nextSteps = nextStepsMatch?.groupValues?.get(1)
            ?.lines()
            ?.map { it.trim().removePrefix("-").trim() }
            ?.filter { it.isNotEmpty() }
            ?: emptyList()

        return Pair(summary, nextSteps)
    }

    fun release() {
        model = null
    }
}
