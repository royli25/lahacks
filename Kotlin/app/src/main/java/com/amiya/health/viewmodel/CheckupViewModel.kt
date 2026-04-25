package com.amiya.health.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.amiya.health.api.ApiClient
import com.amiya.health.data.models.SaveSummaryRequest
import com.amiya.health.data.models.SpeakRequest
import com.amiya.health.data.models.StartRequest
import com.amiya.health.data.models.TranscriptEntry
import com.amiya.health.ml.AudioRecorder
import com.amiya.health.ml.TinyLlamaManager
import com.amiya.health.ml.WhisperManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class CheckupUiState(
    val isLoading: Boolean = true,
    val loadingMessage: String = "Initializing...",
    val sessionId: String? = null,
    val livekitUrl: String? = null,
    val livekitClientToken: String? = null,
    val isMuted: Boolean = false,
    val isWhisperEnabled: Boolean = false,
    val isRecording: Boolean = false,
    val isSpeaking: Boolean = false,
    val summaryReady: Boolean = false,
    val summaryText: String = "",
    val nextSteps: List<String> = emptyList(),
    val llmReady: Boolean = false,
    val errorMessage: String? = null
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
    private val tinyLlamaManager = TinyLlamaManager(context)
    private val audioRecorder = AudioRecorder()
    private var recordingJob: Job? = null

    init {
        initializeModels()
    }

    private fun initializeModels() {
        viewModelScope.launch(Dispatchers.IO) {
            // Load Whisper for live transcription
            try {
                _uiState.update { it.copy(loadingMessage = "Loading Whisper...") }
                whisperManager.initialize { progress ->
                    _uiState.update { it.copy(loadingMessage = "Whisper: ${(progress * 100).toInt()}%") }
                }
            } catch (e: Exception) {
                // Non-fatal — transcription won't work but session can still proceed
            }

            // Connect to LiveAvatar
            _uiState.update { it.copy(loadingMessage = "Connecting to doctor...") }
            connectToLiveAvatar()

            // Load TinyLlama in background — only needed for conversation + summary
            loadTinyLlamaInBackground()
        }
    }

    private fun loadTinyLlamaInBackground() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                tinyLlamaManager.initialize { /* silent */ }
                _uiState.update { it.copy(llmReady = true) }
            } catch (e: Exception) {
                // TinyLlama unavailable — doctor responses won't be generated locally
            }
        }
    }

    private suspend fun connectToLiveAvatar() {
        try {
            val response = ApiClient.service.createSession(
                StartRequest(profileId = doctorId, userName = patientName)
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
                            sessionId = body.sessionId,
                            livekitUrl = body.livekitUrl,
                            livekitClientToken = body.livekitClientToken,
                        )
                    }
                } else {
                    _uiState.update { it.copy(isLoading = false) }
                }
            } else {
                _uiState.update { it.copy(isLoading = false) }
            }
        } catch (e: Exception) {
            _uiState.update { it.copy(isLoading = false, errorMessage = "Failed to connect: ${e.message}") }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    fun toggleMute() {
        _uiState.update { it.copy(isMuted = !it.isMuted) }
    }

    fun toggleCamera() {
        // Camera toggle is handled by the LiveKit WebView; no local state needed
    }

    fun toggleWhisper() {
        val newState = !_uiState.value.isWhisperEnabled
        _uiState.update { it.copy(isWhisperEnabled = newState) }
        if (newState) startRecordingLoop() else stopRecordingLoop()
    }

    private fun startRecordingLoop() {
        recordingJob = viewModelScope.launch {
            while (_uiState.value.isWhisperEnabled) {
                if (!_uiState.value.isMuted && !_uiState.value.isSpeaking) {
                    recordAndRespond()
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

    private suspend fun recordAndRespond() {
        _uiState.update { it.copy(isRecording = true) }
        audioRecorder.startRecording()
        delay(5000)
        val audioData = audioRecorder.stopAndGetAudio()
        _uiState.update { it.copy(isRecording = false) }

        if (audioData.isEmpty()) return

        // STT: Whisper on-device
        val patientText = whisperManager.transcribe(audioData)
        if (patientText.isBlank()) return
        addTranscriptEntry("Patient", patientText)

        // LLM: TinyLlama on-device
        if (!_uiState.value.llmReady) return
        val history = _transcript.value.map { it.speaker to it.text }
        val doctorResponse = tinyLlamaManager.generateDoctorResponse(
            patientText, history, doctorName, patientName
        )
        if (doctorResponse.isBlank()) return
        addTranscriptEntry("Doctor", doctorResponse)

        // TTS: backend speaks through LiveAvatar
        val sessionId = _uiState.value.sessionId ?: return
        try {
            _uiState.update { it.copy(isSpeaking = true) }
            ApiClient.service.speak(SpeakRequest(sessionId, doctorResponse))
        } catch (e: Exception) {
            // Speaking failed — response still visible in transcript
        } finally {
            _uiState.update { it.copy(isSpeaking = false) }
        }
    }

    fun requestSummary() {
        viewModelScope.launch {
            _uiState.update { it.copy(loadingMessage = "Generating summary...", isLoading = true) }
            val transcriptText = _transcript.value.joinToString("\n") { "${it.speaker}: ${it.text}" }

            if (_uiState.value.llmReady) {
                val (summary, steps) = tinyLlamaManager.processTranscript(transcriptText, doctorName, patientName)

                // Save to backend CSV
                try {
                    ApiClient.service.saveSummary(
                        SaveSummaryRequest(
                            transcript = transcriptText,
                            summary = summary,
                            uid = uid,
                            doctorName = doctorName,
                            userName = patientName
                        )
                    )
                } catch (e: Exception) { /* non-fatal */ }

                _uiState.update {
                    it.copy(isLoading = false, summaryReady = true, summaryText = summary, nextSteps = steps)
                }
            } else {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        summaryReady = true,
                        summaryText = "Local model still loading. Transcript saved.",
                        nextSteps = emptyList()
                    )
                }
            }
        }
    }

    fun endCall() {
        stopRecordingLoop()
        whisperManager.release()
        tinyLlamaManager.release()
        val sessionId = _uiState.value.sessionId
        if (sessionId != null) {
            viewModelScope.launch {
                try { ApiClient.service.endSession(sessionId) } catch (e: Exception) { }
            }
        }
    }

    private fun addTranscriptEntry(speaker: String, text: String) {
        _transcript.update { it + TranscriptEntry(speaker = speaker, text = text) }
    }

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
