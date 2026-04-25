package com.amiya.health.api

import com.amiya.health.data.models.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @GET("api/health")
    suspend fun getHealth(): Response<Map<String, Any>>

    @GET("api/profiles")
    suspend fun getProfiles(): Response<List<Map<String, String>>>

    @POST("api/session")
    suspend fun createSession(@Body request: StartRequest): Response<SessionResponse>

    @POST("api/new-patient")
    suspend fun registerPatient(@Body request: NewPatientRequest): Response<PatientResponse>

    @GET("api/patient/{uid}")
    suspend fun getPatient(@Path("uid") uid: String): Response<PatientLookupResponse>

    @POST("api/summarize-transcript")
    suspend fun summarizeTranscript(@Body request: TranscriptSummaryRequest): Response<SummaryResponse>
}
