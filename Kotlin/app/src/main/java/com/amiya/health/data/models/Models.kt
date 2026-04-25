package com.amiya.health.data.models

import com.google.gson.annotations.SerializedName

// ── Doctor ───────────────────────────────────────────────────────────────────

data class DoctorProfile(
    val id: String,
    @SerializedName("agent_name") val agentName: String,
    @SerializedName("avatar_id") val avatarId: String,
    val displayName: String = agentName,
    val specialty: String = "Family Medicine"
)

val DOCTOR_PROFILES = listOf(
    DoctorProfile("alpha", "Dr. Carol Lee",     "alpha_avatar", "Dr. Carol Lee",     "Internal Medicine"),
    DoctorProfile("beta",  "Dr. Dexter Sins",   "beta_avatar",  "Dr. Dexter Sins",   "Family Medicine"),
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
    @SerializedName("deterministic_greeting") val deterministicGreeting: Boolean = true
)

data class SessionResponse(
    @SerializedName("session_id") val sessionId: String,
    @SerializedName("livekit_url") val livekitUrl: String,
    @SerializedName("livekit_client_token") val livekitClientToken: String,
    @SerializedName("ws_url") val wsUrl: String,
    val greeting: String = ""
)

// ── Speak ────────────────────────────────────────────────────────────────────

data class SpeakRequest(
    @SerializedName("session_id") val sessionId: String,
    val text: String
)

data class SpeakResponse(
    val ok: Boolean
)

// ── Summary ──────────────────────────────────────────────────────────────────

data class SaveSummaryRequest(
    val transcript: String,
    val summary: String,
    val uid: String,
    @SerializedName("doctor_name") val doctorName: String,
    @SerializedName("user_name") val userName: String
)

// ── Transcript ────────────────────────────────────────────────────────────────

data class TranscriptEntry(
    val speaker: String,
    val text: String,
    val timestamp: Long = System.currentTimeMillis()
)

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
