package com.amiya.health.ml

import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import com.zeticai.mlange.core.model.ZeticMLangeModel
import com.zeticai.mlange.core.model.ModelMode
import com.zeticai.mlange.core.model.tensor.Tensor
import com.zeticai.mlange.core.model.tensor.TensorDataType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.log10
import kotlin.math.max

class WhisperManager(private val context: Context) {

    private var encoderModel: ZeticMLangeModel? = null
    private var decoderModel: ZeticMLangeModel? = null

    private val ZETIC_API_KEY = "dev_66cf3a5ebcfb48179b4c61b89f96d6ce"
    private val SAMPLE_RATE = 16000
    private val N_FFT = 400
    private val HOP_LENGTH = 160
    private val N_MELS = 80
    private val CHUNK_LENGTH = 30  // seconds
    private val N_SAMPLES = SAMPLE_RATE * CHUNK_LENGTH

    // Whisper token IDs
    private val SOT_TOKEN = 50258
    private val EN_TOKEN = 50259
    private val TRANSCRIBE_TOKEN = 50359
    private val NO_TIMESTAMPS_TOKEN = 50363
    private val EOT_TOKEN = 50256
    private val MAX_NEW_TOKENS = 224

    suspend fun initialize(onProgress: (Float) -> Unit = {}) {
        withContext(Dispatchers.IO) {
            encoderModel = ZeticMLangeModel(
                context,
                ZETIC_API_KEY,
                "OpenAI/whisper-tiny-encoder",
                version = 1,
                modelMode = ModelMode.RUN_AUTO,
                onProgress = { onProgress(it * 0.5f) }
            )
            decoderModel = ZeticMLangeModel(
                context,
                ZETIC_API_KEY,
                "OpenAI/whisper-tiny-decoder",
                version = 1,
                modelMode = ModelMode.RUN_AUTO,
                onProgress = { onProgress(0.5f + it * 0.5f) }
            )
        }
    }

    suspend fun transcribe(audioFloats: FloatArray): String = withContext(Dispatchers.Default) {
        val encoder = encoderModel ?: return@withContext ""
        val decoder = decoderModel ?: return@withContext ""

        val melFeatures = extractMelSpectrogram(audioFloats)

        val melTensor = Tensor.fromFloatArray(
            melFeatures,
            longArrayOf(1, N_MELS.toLong(), 3000L),
            TensorDataType.FLOAT32
        )
        val encoderOutputs = encoder.run(arrayOf(melTensor))

        val tokens = mutableListOf(SOT_TOKEN, EN_TOKEN, TRANSCRIBE_TOKEN, NO_TIMESTAMPS_TOKEN)
        val sb = StringBuilder()

        repeat(MAX_NEW_TOKENS) {
            val tokensTensor = Tensor.fromIntArray(
                tokens.toIntArray(),
                longArrayOf(1, tokens.size.toLong()),
                TensorDataType.INT32
            )
            val inputs = arrayOf(encoderOutputs[0], tokensTensor)
            val decoderOutputs = decoder.run(inputs)

            val logits = decoderOutputs[0].floatArray
            val lastTokenLogits = logits.takeLast(logits.size / tokens.size).toFloatArray()
            val nextToken = lastTokenLogits.indices.maxByOrNull { lastTokenLogits[it] } ?: EOT_TOKEN

            if (nextToken == EOT_TOKEN) return@repeat
            tokens.add(nextToken)
            sb.append(whisperTokenToText(nextToken))
        }

        sb.toString().trim()
    }

    private fun extractMelSpectrogram(audio: FloatArray): FloatArray {
        val paddedAudio = if (audio.size < N_SAMPLES) {
            audio + FloatArray(N_SAMPLES - audio.size)
        } else {
            audio.copyOf(N_SAMPLES)
        }

        val numFrames = 3000
        val melSpec = Array(N_MELS) { FloatArray(numFrames) }
        val melFilterbank = buildMelFilterbank()

        for (frame in 0 until numFrames) {
            val start = frame * HOP_LENGTH
            val frameData = FloatArray(N_FFT) { i ->
                if (start + i < paddedAudio.size) paddedAudio[start + i] else 0f
            }
            applyHannWindow(frameData)
            val magnitudes = computeFFTMagnitudes(frameData)

            for (mel in 0 until N_MELS) {
                var energy = 0f
                for (freq in magnitudes.indices) {
                    energy += magnitudes[freq] * melFilterbank[mel][freq]
                }
                melSpec[mel][frame] = max(energy, 1e-10f)
            }
        }

        val logMelSpec = FloatArray(N_MELS * numFrames)
        var maxVal = Float.NEGATIVE_INFINITY
        for (m in 0 until N_MELS) {
            for (f in 0 until numFrames) {
                val v = 10f * log10(melSpec[m][f])
                logMelSpec[m * numFrames + f] = v
                if (v > maxVal) maxVal = v
            }
        }
        val threshold = maxVal - 8f * 10f
        for (i in logMelSpec.indices) {
            logMelSpec[i] = (maxOf(logMelSpec[i], threshold) + 4f * 10f) / (4f * 10f)
        }

        return logMelSpec
    }

    private fun buildMelFilterbank(): Array<FloatArray> {
        val freqs = FloatArray(N_FFT / 2 + 1) { i -> i * SAMPLE_RATE.toFloat() / N_FFT }
        val melMin = hzToMel(0f)
        val melMax = hzToMel(SAMPLE_RATE / 2f)
        val melPoints = FloatArray(N_MELS + 2) { i ->
            melToHz(melMin + i * (melMax - melMin) / (N_MELS + 1))
        }

        return Array(N_MELS) { m ->
            FloatArray(N_FFT / 2 + 1) { f ->
                val freq = freqs[f]
                when {
                    freq < melPoints[m] -> 0f
                    freq <= melPoints[m + 1] -> (freq - melPoints[m]) / (melPoints[m + 1] - melPoints[m])
                    freq <= melPoints[m + 2] -> (melPoints[m + 2] - freq) / (melPoints[m + 2] - melPoints[m + 1])
                    else -> 0f
                }
            }
        }
    }

    private fun hzToMel(hz: Float) = 2595f * log10(1f + hz / 700f)
    private fun melToHz(mel: Float) = 700f * (Math.pow(10.0, mel / 2595.0).toFloat() - 1f)

    private fun applyHannWindow(frame: FloatArray) {
        for (i in frame.indices) {
            frame[i] *= (0.5f * (1f - kotlin.math.cos(2.0 * Math.PI * i / (frame.size - 1)).toFloat()))
        }
    }

    private fun computeFFTMagnitudes(frame: FloatArray): FloatArray {
        val n = frame.size
        val real = frame.copyOf()
        val imag = FloatArray(n)
        fft(real, imag)
        return FloatArray(n / 2 + 1) { i ->
            kotlin.math.sqrt(real[i] * real[i] + imag[i] * imag[i])
        }
    }

    private fun fft(real: FloatArray, imag: FloatArray) {
        val n = real.size
        var len = 2
        while (len <= n) {
            val halfLen = len / 2
            val angle = -2.0 * Math.PI / len
            val wRe = kotlin.math.cos(angle).toFloat()
            val wIm = kotlin.math.sin(angle).toFloat()
            var i = 0
            while (i < n) {
                var curRe = 1f; var curIm = 0f
                for (j in 0 until halfLen) {
                    val uRe = real[i + j]; val uIm = imag[i + j]
                    val vRe = real[i + j + halfLen] * curRe - imag[i + j + halfLen] * curIm
                    val vIm = real[i + j + halfLen] * curIm + imag[i + j + halfLen] * curRe
                    real[i + j] = uRe + vRe; imag[i + j] = uIm + vIm
                    real[i + j + halfLen] = uRe - vRe; imag[i + j + halfLen] = uIm - vIm
                    val nextRe = curRe * wRe - curIm * wIm
                    curIm = curRe * wIm + curIm * wRe; curRe = nextRe
                }
                i += len
            }
            len *= 2
        }
    }

    private fun whisperTokenToText(token: Int): String {
        // Whisper uses byte-level BPE; for a full implementation, load the tokenizer vocab.
        // This stub returns the token as a placeholder; in production load whisper's vocab.json.
        return ""
    }

    fun release() {
        encoderModel = null
        decoderModel = null
    }
}

// Extension to concatenate float arrays
private operator fun FloatArray.plus(other: FloatArray): FloatArray {
    val result = FloatArray(size + other.size)
    System.arraycopy(this, 0, result, 0, size)
    System.arraycopy(other, 0, result, size, other.size)
    return result
}
