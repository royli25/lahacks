package com.amiya.health.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.amiya.health.api.ApiClient
import com.amiya.health.data.models.StartRequest
import com.amiya.health.data.models.TranscriptEntry
import com.amiya.health.data.models.TranscriptSummaryRequest
import com.amiya.health.ml.AudioRecorder
import com.amiya.health.ml.GemmaManager
import com.amiya.health.ml.WhisperManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class CheckupUiState(
    val isLoading: Boolean = true,
    val loadingMessage: String = "Initializing AI models...",
    val heygenToken: String? = null,
    val heygenSession: String? = null,
    val isMuted: Boolean = false,
    val isCameraOn: Boolean = true,
    val isWhisperEnabled: Boolean = false,
    val isRecording: Boolean = false,
    val summaryReady: Boolean = false,
    val summaryText: String = "",
    val nextSteps: List<String> = emptyList()
)

class CheckupViewModel(
    private val context: Context,
    private val uid: String,
    private val patientName: String,
    private val doctorId: String,
    private val doctorName: String
) : ViewModel() {

    private val _uiState = MutableStateFlow(CheckupUiState())
    val uiState: StateFlow<CheckupUiState> = _uiState.asStateFlow()

    private val _transcript = MutableStateFlow<List<TranscriptEntry>>(emptyList())
    val transcript: StateFlow<List<TranscriptEntry>> = _transcript.asStateFlow()

    private val whisperManager = WhisperManager(context)
    private val gemmaManager = GemmaManager(context)
    private val audioRecorder = AudioRecorder()

    private var recordingJob: Job? = null
    private val startTime = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date())

    init {
        initializeModels()
    }

    private fun initializeModels() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                _uiState.update { it.copy(loadingMessage = "Loading Whisper (speech recognition)...") }
                whisperManager.initialize { progress ->
                    _uiState.update { it.copy(loadingMessage = "Whisper: ${(progress * 100).toInt()}%") }
                }

                _uiState.update { it.copy(loadingMessage = "Loading Gemma (language model)...") }
                gemmaManager.initialize { progress ->
                    _uiState.update { it.copy(loadingMessage = "Gemma: ${(progress * 100).toInt()}%") }
                }

                _uiState.update { it.copy(loadingMessage = "Connecting to doctor...") }
                connectToHeygen()

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        loadingMessage = "Error: ${e.message}"
                    )
                }
            }
        }
    }

    private suspend fun connectToHeygen() {
        try {
            val response = ApiClient.service.createSession(
                StartRequest(
                    profileId = doctorId,
                    userName = patientName,
                    deterministicGreeting = true
                )
            )
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null) {
                    if (body.greeting.isNotEmpty()) {
                        addTranscriptEntry("Doctor", body.greeting)
                    }
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            heygenToken = body.token,
                            heygenSession = body.session.toString()
                        )
                    }
                } else {
                    _uiState.update { it.copy(isLoading = false) }
                }
            } else {
                _uiState.update { it.copy(isLoading = false) }
            }
        } catch (e: Exception) {
            // Still proceed without HeyGen if backend unreachable
            _uiState.update { it.copy(isLoading = false) }
        }
    }

    fun toggleMute() {
        _uiState.update { it.copy(isMuted = !it.isMuted) }
    }

    fun toggleCamera() {
        _uiState.update { it.copy(isCameraOn = !it.isCameraOn) }
    }

    fun toggleWhisper() {
        val newState = !_uiState.value.isWhisperEnabled
        _uiState.update { it.copy(isWhisperEnabled = newState) }

        if (newState) {
            startRecordingLoop()
        } else {
            stopRecordingLoop()
        }
    }

    private fun startRecordingLoop() {
        recordingJob = viewModelScope.launch {
            while (_uiState.value.isWhisperEnabled) {
                if (!_uiState.value.isMuted) {
                    recordAndTranscribe()
                }
                delay(500)
            }
        }
    }

    private fun stopRecordingLoop() {
        recordingJob?.cancel()
        recordingJob = null
        _uiState.update { it.copy(isRecording = false) }
        audioRecorder.release()
    }

    private suspend fun recordAndTranscribe() {
        _uiState.update { it.copy(isRecording = true) }
        audioRecorder.startRecording()
        delay(5000) // Record 5-second chunks
        val audioData = audioRecorder.stopAndGetAudio()
        _uiState.update { it.copy(isRecording = false) }

        if (audioData.isEmpty()) return

        val rawText = whisperManager.transcribe(audioData)
        if (rawText.isBlank()) return

        // Use Gemma to clean up the transcription
        val context = buildPatientContext()
        val cleanedText = gemmaManager.processAudioText(rawText, context)
        val finalText = cleanedText.ifBlank { rawText }

        addTranscriptEntry("Patient", finalText)
    }

    fun requestSummary() {
        viewModelScope.launch {
            _uiState.update { it.copy(loadingMessage = "Generating summary...", isLoading = true) }

            val transcriptText = _transcript.value.joinToString("\n") { "${it.speaker}: ${it.text}" }
            val currentTime = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date())

            try {
                // First try the backend
                val response = ApiClient.service.summarizeTranscript(
                    TranscriptSummaryRequest(
                        transcript = transcriptText,
                        startTime = startTime,
                        currentTime = currentTime,
                        phoneNumber = "",
                        uid = uid,
                        doctorName = doctorName,
                        userName = patientName
                    )
                )

                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            summaryReady = true,
                            summaryText = body.summary,
                            nextSteps = body.nextSteps
                        )
                    }
                } else {
                    // Fall back to local Gemma
                    generateLocalSummary(transcriptText)
                }
            } catch (e: Exception) {
                generateLocalSummary(transcriptText)
            }
        }
    }

    private suspend fun generateLocalSummary(transcriptText: String) {
        val (summary, steps) = gemmaManager.processTranscript(transcriptText, doctorName, patientName)
        _uiState.update {
            it.copy(
                isLoading = false,
                summaryReady = true,
                summaryText = summary,
                nextSteps = steps
            )
        }
    }

    fun endCall() {
        stopRecordingLoop()
        whisperManager.release()
        gemmaManager.release()
    }

    private fun addTranscriptEntry(speaker: String, text: String) {
        _transcript.update { current ->
            current + TranscriptEntry(speaker = speaker, text = text)
        }
    }

    private fun buildPatientContext(): String =
        "Patient name: $patientName. Doctor: $doctorName. Checkup session."

    override fun onCleared() {
        super.onCleared()
        endCall()
    }
}

class CheckupViewModelFactory(
    private val context: Context,
    private val uid: String,
    private val patientName: String,
    private val doctorId: String,
    private val doctorName: String
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        @Suppress("UNCHECKED_CAST")
        return CheckupViewModel(context, uid, patientName, doctorId, doctorName) as T
    }
}
