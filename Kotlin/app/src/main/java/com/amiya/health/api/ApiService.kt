package com.amiya.health.api

import com.amiya.health.data.models.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @GET("api/profiles")
    suspend fun getProfiles(): Response<List<Map<String, String>>>

    @POST("api/session")
    suspend fun createSession(@Body request: StartRequest): Response<SessionResponse>

    @POST("api/speak")
    suspend fun speak(@Body request: SpeakRequest): Response<SpeakResponse>

    @DELETE("api/session/{session_id}")
    suspend fun endSession(@Path("session_id") sessionId: String): Response<Unit>

    @POST("api/new-patient")
    suspend fun registerPatient(@Body request: NewPatientRequest): Response<PatientResponse>

    @GET("api/patient/{uid}")
    suspend fun getPatient(@Path("uid") uid: String): Response<PatientLookupResponse>

    @POST("api/save-summary")
    suspend fun saveSummary(@Body request: SaveSummaryRequest): Response<Map<String, Boolean>>
}
