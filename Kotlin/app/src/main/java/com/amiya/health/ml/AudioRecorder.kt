package com.amiya.health.ml

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AudioRecorder {

    private var audioRecord: AudioRecord? = null
    private val recordedSamples = mutableListOf<Short>()
    private var isRecording = false

    private val SAMPLE_RATE = 16000
    private val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private val BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * 4

    @SuppressLint("MissingPermission")
    fun startRecording() {
        recordedSamples.clear()
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT,
            BUFFER_SIZE
        )
        audioRecord?.startRecording()
        isRecording = true

        Thread {
            val buffer = ShortArray(BUFFER_SIZE / 2)
            while (isRecording) {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: break
                if (read > 0) {
                    synchronized(recordedSamples) {
                        recordedSamples.addAll(buffer.take(read))
                    }
                }
            }
        }.start()
    }

    suspend fun stopAndGetAudio(): FloatArray = withContext(Dispatchers.IO) {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null

        val samples = synchronized(recordedSamples) { recordedSamples.toList() }
        samples.map { it / 32768f }.toFloatArray()
    }

    fun release() {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        recordedSamples.clear()
    }
}
