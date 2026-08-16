package com.mycarejournals.nano_lab

import android.os.Build
import android.os.SystemClock
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.Candidate
import com.google.mlkit.genai.prompt.GenerateContentRequest
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerationConfig
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.ModelConfig
import com.google.mlkit.genai.prompt.ModelReleaseStage
import com.google.mlkit.genai.prompt.SystemInstruction
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.java.GenerativeModelFutures
import com.google.mlkit.genai.summarization.Summarization
import com.google.mlkit.genai.summarization.SummarizationRequest
import com.google.mlkit.genai.summarization.Summarizer
import com.google.mlkit.genai.summarization.SummarizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor

class MainActivity : FlutterActivity() {
    private companion object {
        const val METHOD_CHANNEL = "com.mycarejournals.nano_lab/native"
        const val DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/download_events"
        const val PROMPT_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/prompt_events"
        const val SUMMARIZATION_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/summarization_download_events"

        const val METHOD_GET_PROMPT_STATUS = "getPromptStatus"
        const val METHOD_GET_SYSTEM_INSTRUCTION_STATUS =
            "getSystemInstructionStatus"
        const val METHOD_GET_TOKEN_INFO = "getTokenInfo"
        const val METHOD_START_PROMPT_DOWNLOAD = "startPromptDownload"
        const val METHOD_RUN_PROMPT = "runPrompt"
        const val METHOD_SET_MODEL_RELEASE_STAGE = "setModelReleaseStage"
        const val METHOD_GET_SUMMARIZATION_STATUS = "getSummarizationStatus"
        const val METHOD_START_SUMMARIZATION_DOWNLOAD =
            "startSummarizationDownload"
        const val METHOD_RUN_SUMMARIZATION = "runSummarization"
    }

    private lateinit var generativeModel: GenerativeModel
    private lateinit var generativeModelFutures: GenerativeModelFutures
    private var modelReleaseStage = ModelReleaseStage.STABLE
    private var modelReleaseStageName = "STABLE"
    private lateinit var summarizer: Summarizer

    private var downloadEventSink: EventChannel.EventSink? = null
    private var promptEventSink: EventChannel.EventSink? = null
    private var summarizationDownloadEventSink: EventChannel.EventSink? = null

    @Volatile
    private var isDownloadInProgress = false

    @Volatile
    private var isInferenceInProgress = false

    @Volatile
    private var isSummarizationDownloadInProgress = false

    private var totalDownloadBytes: Long? = null
    private var totalSummarizationDownloadBytes: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        configureGenerativeModel(ModelReleaseStage.STABLE, "STABLE")
        configureSummarizer()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_PROMPT_STATUS -> checkPromptStatus(result)
                METHOD_GET_SYSTEM_INSTRUCTION_STATUS ->
                    checkSystemInstructionStatus(result)
                METHOD_GET_TOKEN_INFO ->
                    getTokenInfo(
                        call.argument<String>("prompt"),
                        call.argument<String>("systemInstruction"),
                        call.argument<Number>("temperature")?.toDouble(),
                        call.argument<Number>("maxOutputTokens")?.toInt(),
                        call.argument<Number>("seed")?.toInt(),
                        call.argument<Number>("topK")?.toInt(),
                        call.argument<Number>("candidateCount")?.toInt(),
                        result,
                    )
                METHOD_START_PROMPT_DOWNLOAD -> startPromptDownload(result)
                METHOD_SET_MODEL_RELEASE_STAGE ->
                    setModelReleaseStage(
                        call.argument<String>("modelReleaseStage"),
                        result,
                    )
                METHOD_RUN_PROMPT ->
                    runPrompt(
                        call.argument<String>("prompt"),
                        call.argument<String>("systemInstruction"),
                        call.argument<Number>("temperature")?.toDouble(),
                        call.argument<Number>("maxOutputTokens")?.toInt(),
                        call.argument<Number>("seed")?.toInt(),
                        call.argument<Number>("topK")?.toInt(),
                        call.argument<Number>("candidateCount")?.toInt(),
                        result,
                    )
                METHOD_GET_SUMMARIZATION_STATUS ->
                    checkSummarizationStatus(result)
                METHOD_START_SUMMARIZATION_DOWNLOAD ->
                    startSummarizationDownload(result)
                METHOD_RUN_SUMMARIZATION ->
                    runSummarization(
                        call.argument<String>("text"),
                        result,
                    )
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    downloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    downloadEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROMPT_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    promptEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    promptEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SUMMARIZATION_DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    summarizationDownloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    summarizationDownloadEventSink = null
                }
            },
        )
    }

    private fun configureGenerativeModel(
        releaseStage: Int,
        releaseStageName: String,
    ) {
        val modelConfig =
            ModelConfig.Builder().apply {
                this.releaseStage = releaseStage
            }.build()
        val generationConfig =
            GenerationConfig.Builder().apply {
                this.modelConfig = modelConfig
            }.build()

        generativeModel = Generation.getClient(generationConfig)
        generativeModelFutures = GenerativeModelFutures.from(generativeModel)
        modelReleaseStage = releaseStage
        modelReleaseStageName = releaseStageName
    }

    private fun configureSummarizer() {
        val options =
            SummarizerOptions.builder(this)
                .setInputType(SummarizerOptions.InputType.ARTICLE)
                .setOutputType(SummarizerOptions.OutputType.ONE_BULLET)
                .setLanguage(SummarizerOptions.Language.ENGLISH)
                .build()

        summarizer = Summarization.getClient(options)
    }

    private fun setModelReleaseStage(
        requestedStage: String?,
        result: MethodChannel.Result,
    ) {
        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress
        ) {
            result.error(
                "MODEL_CHANGE_BLOCKED",
                "Wait for the current Gemini Nano operation to finish.",
                null,
            )
            return
        }

        val releaseStage =
            when (requestedStage) {
                "STABLE" -> ModelReleaseStage.STABLE
                "PREVIEW" -> ModelReleaseStage.PREVIEW
                else -> {
                    result.error(
                        "INVALID_MODEL_RELEASE_STAGE",
                        "Model release stage must be STABLE or PREVIEW.",
                        null,
                    )
                    return
                }
            }

        configureGenerativeModel(releaseStage, requestedStage)
        result.success(mapOf("modelReleaseStage" to modelReleaseStageName))
    }

    private fun checkPromptStatus(result: MethodChannel.Result) {
        val statusFuture = generativeModelFutures.checkStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    val status = statusFuture.get()
                    result.success(
                        createStatusResult(status) +
                            ("modelReleaseStage" to modelReleaseStageName),
                    )
                } catch (error: Exception) {
                    sendStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun checkSystemInstructionStatus(result: MethodChannel.Result) {
        val statusFuture = generativeModelFutures.isSystemPromptAvailable()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    val isAvailable = statusFuture.get()

                    result.success(
                        mapOf(
                            "available" to isAvailable,
                            "description" to
                                if (isAvailable) {
                                    "System instructions are supported on this device."
                                } else {
                                    "System instructions are not supported on this device."
                                },
                        ),
                    )
                } catch (error: Exception) {
                    sendSystemInstructionStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun startPromptDownload(result: MethodChannel.Result) {
        if (isDownloadInProgress || isSummarizationDownloadInProgress) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano download is already running.",
                null,
            )
            return
        }

        if (downloadEventSink == null) {
            result.error(
                "DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive download progress.",
                null,
            )
            return
        }

        isDownloadInProgress = true
        totalDownloadBytes = null

        try {
            generativeModelFutures.download(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) {
                        totalDownloadBytes = bytesToDownload

                        sendDownloadEvent(
                            mapOf(
                                "event" to "started",
                                "totalBytes" to bytesToDownload,
                            ),
                        )
                    }

                    override fun onDownloadProgress(totalBytesDownloaded: Long) {
                        sendDownloadEvent(
                            mapOf(
                                "event" to "progress",
                                "downloadedBytes" to totalBytesDownloaded,
                                "totalBytes" to totalDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadCompleted() {
                        isDownloadInProgress = false

                        sendDownloadEvent(
                            mapOf(
                                "event" to "completed",
                                "downloadedBytes" to totalDownloadBytes,
                                "totalBytes" to totalDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadFailed(e: GenAiException) {
                        isDownloadInProgress = false

                        sendDownloadEvent(
                            mapOf(
                                "event" to "failed",
                                "message" to
                                    (e.message ?: "Gemini Nano download failed."),
                                "errorCode" to e.errorCode,
                            ),
                        )
                    }
                },
            )

            result.success(mapOf("started" to true))
        } catch (error: Exception) {
            isDownloadInProgress = false

            result.error(
                "DOWNLOAD_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun checkSummarizationStatus(result: MethodChannel.Result) {
        val statusFuture = summarizer.checkFeatureStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    result.success(createSummarizationStatusResult(statusFuture.get()))
                } catch (error: Exception) {
                    sendSummarizationStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun startSummarizationDownload(result: MethodChannel.Result) {
        if (isDownloadInProgress || isSummarizationDownloadInProgress) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano download is already running.",
                null,
            )
            return
        }

        if (summarizationDownloadEventSink == null) {
            result.error(
                "SUMMARIZATION_DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive summarization download progress.",
                null,
            )
            return
        }

        isSummarizationDownloadInProgress = true
        totalSummarizationDownloadBytes = null

        try {
            summarizer.downloadFeature(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) {
                        totalSummarizationDownloadBytes = bytesToDownload

                        sendSummarizationDownloadEvent(
                            mapOf(
                                "event" to "started",
                                "totalBytes" to bytesToDownload,
                            ),
                        )
                    }

                    override fun onDownloadProgress(totalBytesDownloaded: Long) {
                        sendSummarizationDownloadEvent(
                            mapOf(
                                "event" to "progress",
                                "downloadedBytes" to totalBytesDownloaded,
                                "totalBytes" to totalSummarizationDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadCompleted() {
                        isSummarizationDownloadInProgress = false

                        sendSummarizationDownloadEvent(
                            mapOf(
                                "event" to "completed",
                                "downloadedBytes" to totalSummarizationDownloadBytes,
                                "totalBytes" to totalSummarizationDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadFailed(e: GenAiException) {
                        isSummarizationDownloadInProgress = false

                        sendSummarizationDownloadEvent(
                            mapOf(
                                "event" to "failed",
                                "message" to
                                    (e.message ?: "Summarization asset download failed."),
                                "errorCode" to e.errorCode,
                            ),
                        )
                    }
                },
            )

            result.success(mapOf("started" to true))
        } catch (error: Exception) {
            isSummarizationDownloadInProgress = false

            result.error(
                "SUMMARIZATION_DOWNLOAD_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun runSummarization(
        text: String?,
        result: MethodChannel.Result,
    ) {
        if (text.isNullOrBlank()) {
            result.error(
                "INVALID_SUMMARIZATION_INPUT",
                "Enter article text before starting summarization.",
                null,
            )
            return
        }

        if (text.length <= 400) {
            result.error(
                "SUMMARIZATION_INPUT_TOO_SHORT",
                "Article input must contain more than 400 characters.",
                null,
            )
            return
        }

        if (isInferenceInProgress) {
            result.error(
                "INFERENCE_ALREADY_RUNNING",
                "A Gemini Nano inference is already running.",
                null,
            )
            return
        }

        isInferenceInProgress = true
        val startedAt = SystemClock.elapsedRealtime()

        try {
            val request = SummarizationRequest.builder(text).build()
            val inferenceFuture = summarizer.runInference(request)
            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        val summary = inferenceFuture.get().summary
                        isInferenceInProgress = false

                        result.success(
                            mapOf(
                                "input" to text,
                                "output" to summary,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    } catch (error: Exception) {
                        isInferenceInProgress = false
                        sendSummarizationInferenceError(result, error, startedAt)
                    }
                },
                mainExecutor,
            )
        } catch (error: Exception) {
            isInferenceInProgress = false
            sendSummarizationInferenceError(result, error, startedAt)
        }
    }

    private fun getTokenInfo(
        prompt: String?,
        systemInstruction: String?,
        temperature: Double?,
        maxOutputTokens: Int?,
        seed: Int?,
        topK: Int?,
        candidateCount: Int?,
        result: MethodChannel.Result,
    ) {
        if (prompt.isNullOrBlank()) {
            result.error(
                "INVALID_PROMPT",
                "Enter a prompt before counting tokens.",
                null,
            )
            return
        }

        if (!validateGenerationSettings(
                temperature,
                maxOutputTokens,
                seed,
                topK,
                candidateCount,
                result,
            )
        ) {
            return
        }

        val systemInstructionText =
            systemInstruction?.takeUnless { it.isBlank() }
        val request =
            createGenerateContentRequest(
                prompt,
                systemInstructionText,
                temperature,
                maxOutputTokens,
                seed,
                topK,
                candidateCount,
            )
        val countFuture = generativeModelFutures.countTokens(request)
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        countFuture.addListener(
            {
                try {
                    val requestTokens = countFuture.get().totalTokens
                    val limitFuture = generativeModelFutures.getTokenLimit()

                    limitFuture.addListener(
                        {
                            try {
                                result.success(
                                    mapOf(
                                        "requestTokens" to requestTokens,
                                        "tokenLimit" to limitFuture.get(),
                                        "prompt" to prompt,
                                        "systemInstruction" to systemInstructionText,
                                        "temperature" to temperature,
                                        "maxOutputTokens" to maxOutputTokens,
                                        "seed" to seed,
                                        "topK" to topK,
                                        "candidateCount" to candidateCount,
                                        "modelReleaseStage" to modelReleaseStageName,
                                    ),
                                )
                            } catch (error: Exception) {
                                sendTokenInfoError(result, error)
                            }
                        },
                        mainExecutor,
                    )
                } catch (error: Exception) {
                    sendTokenInfoError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun runPrompt(
        prompt: String?,
        systemInstruction: String?,
        temperature: Double?,
        maxOutputTokens: Int?,
        seed: Int?,
        topK: Int?,
        candidateCount: Int?,
        result: MethodChannel.Result,
    ) {
        if (prompt.isNullOrBlank()) {
            result.error(
                "INVALID_PROMPT",
                "Enter a prompt before starting Gemini Nano inference.",
                null,
            )
            return
        }

        if (!validateGenerationSettings(
                temperature,
                maxOutputTokens,
                seed,
                topK,
                candidateCount,
                result,
            )
        ) {
            return
        }

        if (isInferenceInProgress) {
            result.error(
                "INFERENCE_ALREADY_RUNNING",
                "A Gemini Nano inference is already running.",
                null,
            )
            return
        }

        if (promptEventSink == null) {
            result.error(
                "PROMPT_LISTENER_MISSING",
                "Flutter is not ready to receive streaming prompt output.",
                null,
            )
            return
        }

        val systemInstructionText =
            systemInstruction?.takeUnless { it.isBlank() }

        isInferenceInProgress = true
        val startedAt = SystemClock.elapsedRealtime()

        sendPromptEvent(
            mapOf(
                "event" to "started",
                "prompt" to prompt,
                "systemInstruction" to systemInstructionText,
                "temperature" to temperature,
                "maxOutputTokens" to maxOutputTokens,
                "seed" to seed,
                "topK" to topK,
                "candidateCount" to candidateCount,
                "modelReleaseStage" to modelReleaseStageName,
            ),
        )

        try {
            val request =
                createGenerateContentRequest(
                    prompt,
                    systemInstructionText,
                    temperature,
                    maxOutputTokens,
                    seed,
                    topK,
                    candidateCount,
                )

            val inferenceFuture =
                if (candidateCount == 1) {
                    generativeModelFutures.generateContent(request) { chunk ->
                        sendPromptEvent(
                            mapOf(
                                "event" to "chunk",
                                "text" to chunk,
                            ),
                        )
                    }
                } else {
                    generativeModelFutures.generateContent(request)
                }

            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        val response = inferenceFuture.get()
                        val finishReason =
                            response.candidates.first().finishReason
                        val candidates =
                            response.candidates.map { candidate ->
                                mapOf(
                                    "text" to candidate.text,
                                    "finishReason" to
                                        createFinishReasonName(candidate.finishReason),
                                    "finishReasonCode" to candidate.finishReason,
                                )
                            }
                        isInferenceInProgress = false

                        sendPromptEvent(
                            mapOf(
                                "event" to "completed",
                                "finishReason" to
                                    createFinishReasonName(finishReason),
                                "finishReasonCode" to finishReason,
                                "candidates" to candidates,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    } catch (error: Exception) {
                        isInferenceInProgress = false
                        sendPromptFailure(error, startedAt)
                    }
                },
                mainExecutor,
            )

            result.success(
                mapOf(
                    "started" to true,
                    "prompt" to prompt,
                    "systemInstruction" to systemInstructionText,
                    "temperature" to temperature,
                    "maxOutputTokens" to maxOutputTokens,
                    "seed" to seed,
                    "topK" to topK,
                    "candidateCount" to candidateCount,
                    "modelReleaseStage" to modelReleaseStageName,
                ),
            )
        } catch (error: Exception) {
            isInferenceInProgress = false
            sendPromptFailure(error, startedAt)

            result.error(
                "INFERENCE_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun sendDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            downloadEventSink?.success(event)
        }
    }

    private fun sendPromptEvent(event: Map<String, Any?>) {
        runOnUiThread {
            promptEventSink?.success(event)
        }
    }

    private fun sendSummarizationDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            summarizationDownloadEventSink?.success(event)
        }
    }

    private fun sendPromptFailure(
        error: Exception,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)

        val event =
            if (cause is GenAiException) {
                mapOf(
                    "event" to "failed",
                    "message" to
                        (cause.message ?: "Gemini Nano inference failed."),
                    "errorCode" to cause.errorCode,
                    "elapsedMilliseconds" to
                        SystemClock.elapsedRealtime() - startedAt,
                )
            } else {
                mapOf(
                    "event" to "failed",
                    "message" to (cause.message ?: cause.toString()),
                    "elapsedMilliseconds" to
                        SystemClock.elapsedRealtime() - startedAt,
                )
            }

        sendPromptEvent(event)
    }

    private fun sendSummarizationInferenceError(
        result: MethodChannel.Result,
        error: Exception,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)
        val elapsedMilliseconds = SystemClock.elapsedRealtime() - startedAt

        if (cause is GenAiException) {
            result.error(
                "GENAI_SUMMARIZATION_${cause.errorCode}",
                cause.message ?: "Gemini Nano summarization failed.",
                mapOf(
                    "errorCode" to cause.errorCode,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                ),
            )
        } else {
            result.error(
                "SUMMARIZATION_FAILED",
                cause.message ?: cause.toString(),
                mapOf("elapsedMilliseconds" to elapsedMilliseconds),
            )
        }
    }

    private fun createGenerateContentRequest(
        prompt: String,
        systemInstruction: String?,
        temperature: Double?,
        maxOutputTokens: Int?,
        seed: Int?,
        topK: Int?,
        candidateCount: Int?,
    ): GenerateContentRequest {
        val builder =
            if (systemInstruction == null) {
                GenerateContentRequest.Builder(
                    TextPart(prompt),
                )
            } else {
                GenerateContentRequest.Builder(
                    SystemInstruction(systemInstruction),
                    TextPart(prompt),
                )
            }

        temperature?.let { builder.temperature = it.toFloat() }
        maxOutputTokens?.let { builder.maxOutputTokens = it }
        seed?.let { builder.seed = it }
        topK?.let { builder.topK = it }
        candidateCount?.let { builder.candidateCount = it }

        return builder.build()
    }

    private fun validateGenerationSettings(
        temperature: Double?,
        maxOutputTokens: Int?,
        seed: Int?,
        topK: Int?,
        candidateCount: Int?,
        result: MethodChannel.Result,
    ): Boolean {
        if (temperature != null && temperature !in 0.0..1.0) {
            result.error(
                "INVALID_TEMPERATURE",
                "Temperature must be between 0.0 and 1.0.",
                null,
            )
            return false
        }

        if (maxOutputTokens != null && maxOutputTokens !in 1..4096) {
            result.error(
                "INVALID_MAX_OUTPUT_TOKENS",
                "Maximum output tokens must be between 1 and 4096.",
                null,
            )
            return false
        }

        if (seed != null && seed < 0) {
            result.error(
                "INVALID_SEED",
                "Seed must be a non-negative whole number.",
                null,
            )
            return false
        }

        if (topK != null && topK < 1) {
            result.error(
                "INVALID_TOP_K",
                "Top-K must be a positive whole number.",
                null,
            )
            return false
        }

        if (candidateCount != null && candidateCount !in 1..8) {
            result.error(
                "INVALID_CANDIDATE_COUNT",
                "Candidate count must be between 1 and 8.",
                null,
            )
            return false
        }

        return true
    }

    private fun createFinishReasonName(finishReason: Int?): String {
        return when (finishReason) {
            Candidate.FinishReason.STOP -> "STOP"
            Candidate.FinishReason.MAX_TOKENS -> "MAX_TOKENS"
            Candidate.FinishReason.OTHER -> "OTHER"
            null -> "UNKNOWN"
            else -> "UNKNOWN"
        }
    }

    private fun createStatusResult(status: Int): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description = "Gemini Nano is downloaded and ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports Gemini Nano, but the required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description = "The required Gemini Nano assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "The Prompt API is unavailable, or AICore has not finished retrieving its configuration."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Prompt API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkLevel" to Build.VERSION.SDK_INT,
        )
    }

    private fun createSummarizationStatusResult(status: Int): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description = "The dedicated Summarization API is ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports summarization, but its required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description = "The required summarization assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "The selected English article summarization configuration is unavailable."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Summarization API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
        )
    }

    private fun sendStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_STATUS_${cause.errorCode}",
                cause.message ?: "Gemini Nano status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "STATUS_CHECK_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendSystemInstructionStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_SYSTEM_INSTRUCTION_STATUS_${cause.errorCode}",
                cause.message ?: "System-instruction capability detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "SYSTEM_INSTRUCTION_STATUS_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendSummarizationStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_SUMMARIZATION_STATUS_${cause.errorCode}",
                cause.message ?: "Summarization status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "SUMMARIZATION_STATUS_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendTokenInfoError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_TOKEN_INFO_${cause.errorCode}",
                cause.message ?: "Gemini Nano token information failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "TOKEN_INFO_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun unwrapExecutionError(error: Exception): Throwable {
        return if (error is ExecutionException) {
            error.cause ?: error
        } else {
            error
        }
    }

    override fun onDestroy() {
        downloadEventSink = null
        promptEventSink = null
        summarizationDownloadEventSink = null

        if (::generativeModel.isInitialized) {
            generativeModel.close()
        }

        if (::summarizer.isInitialized) {
            summarizer.close()
        }

        super.onDestroy()
    }
}
