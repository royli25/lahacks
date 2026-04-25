package com.amiya.health.ml

import android.content.Context
import com.zeticai.mlange.core.model.llm.ZeticMLangeLLMModel
import com.zeticai.mlange.core.model.llm.LLMModelMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext

class TinyLlamaManager(private val context: Context) {

    private var model: ZeticMLangeLLMModel? = null

    private val ZETIC_API_KEY = "dev_66cf3a5ebcfb48179b4c61b89f96d6ce"

    suspend fun initialize(onProgress: (Float) -> Unit = {}) {
        withContext(Dispatchers.IO) {
            model = ZeticMLangeLLMModel(
                context,
                ZETIC_API_KEY,
                "meta/TinyLlama-1.1B-Chat-v1.0",
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
            if (waitResult.generatedTokens == 0) break
            if (waitResult.token.isNotEmpty()) sb.append(waitResult.token)
        }
        sb.toString().trim()
    }

    fun generateStream(prompt: String): Flow<String> = flow {
        val llm = model ?: return@flow
        withContext(Dispatchers.IO) { llm.run(prompt) }
        while (true) {
            val waitResult = withContext(Dispatchers.IO) { llm.waitForNextToken() }
            if (waitResult.generatedTokens == 0) break
            if (waitResult.token.isNotEmpty()) emit(waitResult.token)
        }
    }

    suspend fun generateDoctorResponse(
        patientSpeech: String,
        conversationHistory: List<Pair<String, String>>,
        doctorName: String,
        patientName: String
    ): String {
        val historyText = conversationHistory.takeLast(6).joinToString("\n") { (speaker, text) ->
            "$speaker: $text"
        }
        val prompt = buildConversationPrompt(patientSpeech, historyText, doctorName, patientName)
        return generate(prompt)
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

    private fun buildConversationPrompt(
        patientSpeech: String,
        history: String,
        doctorName: String,
        patientName: String
    ): String = """<|system|>
You are Dr. $doctorName, a compassionate physician on a telehealth visit with $patientName. Respond warmly in 1-3 sentences. Be medically helpful but concise.</s>
<|user|>
${if (history.isNotEmpty()) "Previous conversation:\n$history\n\n" else ""}Patient says: "$patientSpeech"

Respond as Dr. $doctorName:</s>
<|assistant|>
"""

    private fun buildSummarizationPrompt(
        transcript: String,
        doctorName: String,
        patientName: String
    ): String = """<|system|>
You are a medical scribe. Summarize telehealth consultations concisely and accurately.</s>
<|user|>
Summarize the following consultation between $doctorName and $patientName.

Transcript:
$transcript

Provide a response in this exact format:
SUMMARY: [2-3 sentence clinical summary]
NEXT_STEPS:
- [action item 1]
- [action item 2]
- [action item 3]</s>
<|assistant|>
"""

    private fun parseStructuredOutput(output: String): Pair<String, List<String>> {
        val summaryRegex = Regex("SUMMARY:\\s*(.+?)(?=NEXT_STEPS:|$)", RegexOption.DOT_MATCHES_ALL)
        val summary = summaryRegex.find(output)?.groupValues?.get(1)?.trim() ?: output

        val nextStepsRegex = Regex("NEXT_STEPS:\\s*(.+)", RegexOption.DOT_MATCHES_ALL)
        val nextSteps = nextStepsRegex.find(output)?.groupValues?.get(1)
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
