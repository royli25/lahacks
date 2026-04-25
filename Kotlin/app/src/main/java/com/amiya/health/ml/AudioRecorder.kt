package com.amiya.health.ml

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.nio.ByteOrder

class AudioRecorder {

    private var audioRecord: AudioRecord? = null
    private var isRecording = false

    private val SAMPLE_RATE = 16000
    private val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private val BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * 4

    @SuppressLint("MissingPermission")
    fun startRecording() {
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT,
            BUFFER_SIZE
        )
        audioRecord?.startRecording()
        isRecording = true
    }

    suspend fun stopAndGetAudio(): FloatArray = withContext(Dispatchers.IO) {
        isRecording = false
        val record = audioRecord ?: return@withContext FloatArray(0)
        record.stop()

        val buffer = ShortArray(BUFFER_SIZE / 2)
        val allSamples = mutableListOf<Short>()

        var read: Int
        while (record.read(buffer, 0, buffer.size).also { read = it } > 0) {
            allSamples.addAll(buffer.take(read))
            if (allSamples.size >= SAMPLE_RATE * 30) break
        }

        record.release()
        audioRecord = null

        allSamples.map { it / 32768f }.toFloatArray()
    }

    fun release() {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }
}
