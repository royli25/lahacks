package com.amiya.health.data.models

import com.google.gson.annotations.SerializedName

// ── Doctor ──────────────────────────────────────────────────────────────────

data class DoctorProfile(
    val id: String,
    @SerializedName("agent_name") val agentName: String,
    @SerializedName("avatar_id") val avatarId: String,
    val displayName: String = agentName,
    val specialty: String = "Family Medicine"
)

val DOCTOR_PROFILES = listOf(
    DoctorProfile("alpha", "Dr. Carol Lee", "alpha_avatar", "Dr. Carol Lee", "Internal Medicine"),
    DoctorProfile("beta", "Dr. Dexter Sins", "beta_avatar", "Dr. Dexter Sins", "Family Medicine"),
    DoctorProfile("gamma", "Dr. Karen Roberts", "gamma_avatar", "Dr. Karen Roberts", "Geriatrics"),
)

// ── Patient ──────────────────────────────────────────────────────────────────

data class NewPatientRequest(
    val name: String,
    @SerializedName("phone_number") val phoneNumber: String,
    @SerializedName("agent_name") val agentName: String
)

data class PatientResponse(
    val uid: String,
    val name: String,
    @SerializedName("phone_number") val phoneNumber: String,
    @SerializedName("agent_name") val agentName: String,
    val message: String
)

data class PatientLookupResponse(
    val name: String,
    val doctor: String
)

// ── Session ──────────────────────────────────────────────────────────────────

data class StartRequest(
    @SerializedName("profile_id") val profileId: String,
    @SerializedName("user_name") val userName: String,
    val language: String = "en",
    @SerializedName("deterministic_greeting") val deterministicGreeting: Boolean = false
)

data class SessionResponse(
    val token: String,
    val session: SessionPayload,
    val greeting: String,
    @SerializedName("effective_knowledge") val effectiveKnowledge: String = ""
)

data class SessionPayload(
    val avatarName: String,
    val language: String,
    val quality: String = "medium"
)

// ── Transcript ────────────────────────────────────────────────────────────────

data class TranscriptEntry(
    val speaker: String,  // "Doctor" or "Patient"
    val text: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class TranscriptSummaryRequest(
    val transcript: String,
    @SerializedName("start_time") val startTime: String,
    @SerializedName("current_time") val currentTime: String,
    @SerializedName("phone_number") val phoneNumber: String,
    val uid: String,
    @SerializedName("doctor_name") val doctorName: String,
    @SerializedName("user_name") val userName: String
)

data class SummaryResponse(
    val summary: String,
    @SerializedName("next_steps") val nextSteps: List<String> = emptyList()
)

// ── Audio Processing ──────────────────────────────────────────────────────────

data class AudioProcessRequest(
    @SerializedName("audio_data") val audioData: String,  // base64
    @SerializedName("patient_context") val patientContext: String = ""
)

data class AudioProcessResponse(
    @SerializedName("transcribed_text") val transcribedText: String,
    @SerializedName("processed_text") val processedText: String,
    val success: Boolean
)

// ── Checkup History ───────────────────────────────────────────────────────────

data class CheckupRecord(
    val id: String,
    val date: String,
    val duration: String,
    val status: String,
    val doctorName: String,
    val summary: String,
    val transcript: List<TranscriptEntry>,
    val nextSteps: List<String>
)
