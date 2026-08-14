package com.mycarejournals.nano_lab

import android.os.Build
import android.os.SystemClock
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.GenerateContentRequest
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.SystemInstruction
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.java.GenerativeModelFutures
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

        const val METHOD_GET_PROMPT_STATUS = "getPromptStatus"
        const val METHOD_GET_SYSTEM_INSTRUCTION_STATUS =
            "getSystemInstructionStatus"
        const val METHOD_GET_TOKEN_INFO = "getTokenInfo"
        const val METHOD_START_PROMPT_DOWNLOAD = "startPromptDownload"
        const val METHOD_RUN_PROMPT = "runPrompt"
    }

    private lateinit var generativeModel: GenerativeModel
    private lateinit var generativeModelFutures: GenerativeModelFutures

    private var downloadEventSink: EventChannel.EventSink? = null
    private var promptEventSink: EventChannel.EventSink? = null

    @Volatile
    private var isDownloadInProgress = false

    @Volatile
    private var isInferenceInProgress = false

    private var totalDownloadBytes: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        generativeModel = Generation.getClient()
        generativeModelFutures = GenerativeModelFutures.from(generativeModel)

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
                        result,
                    )
                METHOD_START_PROMPT_DOWNLOAD -> startPromptDownload(result)
                METHOD_RUN_PROMPT ->
                    runPrompt(
                        call.argument<String>("prompt"),
                        call.argument<String>("systemInstruction"),
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
    }

    private fun checkPromptStatus(result: MethodChannel.Result) {
        val statusFuture = generativeModelFutures.checkStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    val status = statusFuture.get()
                    result.success(createStatusResult(status))
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
        if (isDownloadInProgress) {
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

    private fun getTokenInfo(
        prompt: String?,
        systemInstruction: String?,
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

        val systemInstructionText =
            systemInstruction?.takeUnless { it.isBlank() }
        val request = createGenerateContentRequest(prompt, systemInstructionText)
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
            ),
        )

        try {
            val request =
                createGenerateContentRequest(prompt, systemInstructionText)

            val inferenceFuture =
                generativeModelFutures.generateContent(
                    request,
                ) { chunk ->
                    sendPromptEvent(
                        mapOf(
                            "event" to "chunk",
                            "text" to chunk,
                        ),
                    )
                }

            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        inferenceFuture.get()
                        isInferenceInProgress = false

                        sendPromptEvent(
                            mapOf(
                                "event" to "completed",
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

    private fun createGenerateContentRequest(
        prompt: String,
        systemInstruction: String?,
    ): GenerateContentRequest {
        return if (systemInstruction == null) {
            GenerateContentRequest.Builder(
                TextPart(prompt),
            ).build()
        } else {
            GenerateContentRequest.Builder(
                SystemInstruction(systemInstruction),
                TextPart(prompt),
            ).build()
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

        if (::generativeModel.isInitialized) {
            generativeModel.close()
        }

        super.onDestroy()
    }
}
