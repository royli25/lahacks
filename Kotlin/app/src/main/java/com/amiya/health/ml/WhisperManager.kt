package com.amiya.health.ml

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.zeticai.mlange.core.model.ZeticMLangeModel
import com.zeticai.mlange.core.model.ModelMode
import com.zeticai.mlange.core.tensor.Tensor
import com.zeticai.mlange.core.tensor.DataType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.nio.ByteOrder
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.cos
import kotlin.math.sqrt

class WhisperManager(private val context: Context) {

    private var encoderModel: ZeticMLangeModel? = null
    private var decoderModel: ZeticMLangeModel? = null
    private var vocab: List<String> = emptyList()

    private val ZETIC_API_KEY = "dev_66cf3a5ebcfb48179b4c61b89f96d6ce"
    private val SAMPLE_RATE = 16000
    private val N_FFT = 400
    private val HOP_LENGTH = 160
    private val N_MELS = 80
    private val CHUNK_LENGTH = 30
    private val N_SAMPLES = SAMPLE_RATE * CHUNK_LENGTH
    private val NUM_FRAMES = 3000

    private val SOT_TOKEN = 50258
    private val EN_TOKEN = 50259
    private val TRANSCRIBE_TOKEN = 50359
    private val NO_TIMESTAMPS_TOKEN = 50363
    private val EOT_TOKEN = 50256
    private val MAX_NEW_TOKENS = 224

    private fun loadVocab() {
        try {
            val json = context.assets.open("whisper_vocab.json").bufferedReader().readText()
            val type = object : TypeToken<List<String>>() {}.type
            vocab = Gson().fromJson(json, type)
        } catch (e: Exception) {
            vocab = emptyList()
        }
    }

    suspend fun initialize(onProgress: (Float) -> Unit = {}) {
        withContext(Dispatchers.IO) {
            loadVocab()
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

        val melTensor = Tensor.of(
            melFeatures,
            DataType.Float32,
            intArrayOf(1, N_MELS, NUM_FRAMES),
            false
        )
        val encoderOutputs = encoder.run(arrayOf(melTensor))

        val tokens = mutableListOf(SOT_TOKEN, EN_TOKEN, TRANSCRIBE_TOKEN, NO_TIMESTAMPS_TOKEN)
        val sb = StringBuilder()

        repeat(MAX_NEW_TOKENS) {
            val tokenArray = tokens.toIntArray()
            val tokensTensor = Tensor.of(
                tokenArray,
                DataType.Int32,
                intArrayOf(1, tokenArray.size),
                false
            )
            val decoderOutputs = decoder.run(arrayOf(encoderOutputs[0], tokensTensor))

            val logits = readFloats(decoderOutputs[0])
            val stride = if (tokens.size > 0) logits.size / tokens.size else logits.size
            val lastTokenStart = (tokens.size - 1) * stride
            val lastLogits = logits.copyOfRange(lastTokenStart, lastTokenStart + stride)

            val nextToken = lastLogits.indices.maxByOrNull { lastLogits[it] } ?: EOT_TOKEN

            if (nextToken == EOT_TOKEN) return@repeat
            tokens.add(nextToken)
            sb.append(whisperTokenToText(nextToken))
        }

        sb.toString().trim()
    }

    private fun readFloats(tensor: Tensor): FloatArray {
        val buf = tensor.data
        buf.rewind()
        buf.order(ByteOrder.nativeOrder())
        val fb = buf.asFloatBuffer()
        return FloatArray(fb.remaining()) { fb.get() }
    }

    private fun extractMelSpectrogram(audio: FloatArray): FloatArray {
        val paddedAudio = if (audio.size < N_SAMPLES) {
            audio + FloatArray(N_SAMPLES - audio.size)
        } else {
            audio.copyOf(N_SAMPLES)
        }

        val melSpec = Array(N_MELS) { FloatArray(NUM_FRAMES) }
        val melFilterbank = buildMelFilterbank()

        for (frame in 0 until NUM_FRAMES) {
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

        val logMelSpec = FloatArray(N_MELS * NUM_FRAMES)
        var maxVal = Float.NEGATIVE_INFINITY
        for (m in 0 until N_MELS) {
            for (f in 0 until NUM_FRAMES) {
                val v = 10f * log10(melSpec[m][f])
                logMelSpec[m * NUM_FRAMES + f] = v
                if (v > maxVal) maxVal = v
            }
        }
        val threshold = maxVal - 80f
        for (i in logMelSpec.indices) {
            logMelSpec[i] = (max(logMelSpec[i], threshold) + 40f) / 40f
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
            frame[i] *= (0.5f * (1f - cos(2.0 * Math.PI * i / (frame.size - 1)).toFloat()))
        }
    }

    private fun computeFFTMagnitudes(frame: FloatArray): FloatArray {
        val n = frame.size
        val real = frame.copyOf()
        val imag = FloatArray(n)
        fft(real, imag)
        return FloatArray(n / 2 + 1) { i ->
            sqrt(real[i] * real[i] + imag[i] * imag[i])
        }
    }

    private fun fft(real: FloatArray, imag: FloatArray) {
        val n = real.size
        var len = 2
        while (len <= n) {
            val halfLen = len / 2
            val angle = -2.0 * Math.PI / len
            val wRe = cos(angle).toFloat()
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
        return if (token >= 0 && token < vocab.size) vocab[token] else ""
    }

    fun release() {
        encoderModel?.close()
        encoderModel = null
        decoderModel?.close()
        decoderModel = null
    }
}

private operator fun FloatArray.plus(other: FloatArray): FloatArray {
    val result = FloatArray(size + other.size)
    System.arraycopy(this, 0, result, 0, size)
    System.arraycopy(other, 0, result, size, other.size)
    return result
}
