package com.mycarejournals.nano_lab

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.os.Build
import android.os.BatteryManager
import android.os.Debug
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.common.audio.AudioSource
import com.google.mlkit.genai.imagedescription.ImageDescriber
import com.google.mlkit.genai.imagedescription.ImageDescriberOptions
import com.google.mlkit.genai.imagedescription.ImageDescription
import com.google.mlkit.genai.imagedescription.ImageDescriptionRequest
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
import com.google.mlkit.genai.proofreading.Proofreader
import com.google.mlkit.genai.proofreading.ProofreaderOptions
import com.google.mlkit.genai.proofreading.Proofreading
import com.google.mlkit.genai.proofreading.ProofreadingRequest
import com.google.mlkit.genai.summarization.Summarization
import com.google.mlkit.genai.summarization.SummarizationRequest
import com.google.mlkit.genai.summarization.Summarizer
import com.google.mlkit.genai.summarization.SummarizerOptions
import com.google.mlkit.genai.speechrecognition.SpeechRecognition
import com.google.mlkit.genai.speechrecognition.SpeechRecognizer
import com.google.mlkit.genai.speechrecognition.SpeechRecognizerOptions
import com.google.mlkit.genai.speechrecognition.SpeechRecognizerResponse
import com.google.mlkit.genai.speechrecognition.speechRecognizerOptions
import com.google.mlkit.genai.speechrecognition.speechRecognizerRequest
import com.google.mlkit.genai.rewriting.Rewriter
import com.google.mlkit.genai.rewriting.RewriterOptions
import com.google.mlkit.genai.rewriting.Rewriting
import com.google.mlkit.genai.rewriting.RewritingRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private companion object {
        const val METHOD_CHANNEL = "com.mycarejournals.nano_lab/native"
        const val DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/download_events"
        const val PROMPT_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/prompt_events"
        const val SUMMARIZATION_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/summarization_download_events"
        const val REWRITING_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/rewriting_download_events"
        const val PROOFREADING_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/proofreading_download_events"
        const val IMAGE_DESCRIPTION_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/image_description_download_events"
        const val SPEECH_RECOGNITION_DOWNLOAD_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/speech_recognition_download_events"
        const val SPEECH_RECOGNITION_EVENT_CHANNEL =
            "com.mycarejournals.nano_lab/speech_recognition_events"

        const val METHOD_GET_PROMPT_STATUS = "getPromptStatus"
        const val METHOD_GET_MEMORY_SNAPSHOT = "getMemorySnapshot"
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
        const val METHOD_GET_REWRITING_STATUS = "getRewritingStatus"
        const val METHOD_START_REWRITING_DOWNLOAD = "startRewritingDownload"
        const val METHOD_RUN_REWRITING = "runRewriting"
        const val METHOD_GET_PROOFREADING_STATUS = "getProofreadingStatus"
        const val METHOD_START_PROOFREADING_DOWNLOAD =
            "startProofreadingDownload"
        const val METHOD_RUN_PROOFREADING = "runProofreading"
        const val METHOD_GET_IMAGE_DESCRIPTION_STATUS =
            "getImageDescriptionStatus"
        const val METHOD_START_IMAGE_DESCRIPTION_DOWNLOAD =
            "startImageDescriptionDownload"
        const val METHOD_GET_IMAGE_DESCRIPTION_TEST_IMAGE =
            "getImageDescriptionTestImage"
        const val METHOD_RUN_IMAGE_DESCRIPTION = "runImageDescription"
        const val METHOD_GET_SPEECH_RECOGNITION_STATUS =
            "getSpeechRecognitionStatus"
        const val METHOD_START_SPEECH_RECOGNITION_DOWNLOAD =
            "startSpeechRecognitionDownload"
        const val METHOD_REQUEST_SPEECH_RECOGNITION_PERMISSION =
            "requestSpeechRecognitionPermission"
        const val METHOD_START_SPEECH_RECOGNITION =
            "startSpeechRecognition"
        const val METHOD_STOP_SPEECH_RECOGNITION =
            "stopSpeechRecognition"

        const val SYNTHETIC_IMAGE_ID = "synthetic_house_scene_v1"
        const val SYNTHETIC_IMAGE_WIDTH = 768
        const val SYNTHETIC_IMAGE_HEIGHT = 512
        const val REAL_PHOTO_IMAGE_ID = "real_tabletop_photo_v1"
        const val RECORD_AUDIO_PERMISSION_REQUEST_CODE = 2026
    }

    private lateinit var generativeModel: GenerativeModel
    private lateinit var generativeModelFutures: GenerativeModelFutures
    private var modelReleaseStage = ModelReleaseStage.STABLE
    private var modelReleaseStageName = "STABLE"
    private lateinit var summarizer: Summarizer
    private lateinit var rewriter: Rewriter
    private lateinit var proofreader: Proofreader
    private lateinit var imageDescriber: ImageDescriber
    private lateinit var speechRecognizer: SpeechRecognizer
    private val speechCoroutineScope =
        CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var downloadEventSink: EventChannel.EventSink? = null
    private var promptEventSink: EventChannel.EventSink? = null
    private var summarizationDownloadEventSink: EventChannel.EventSink? = null
    private var rewritingDownloadEventSink: EventChannel.EventSink? = null
    private var proofreadingDownloadEventSink: EventChannel.EventSink? = null
    private var imageDescriptionDownloadEventSink: EventChannel.EventSink? = null
    private var speechRecognitionDownloadEventSink: EventChannel.EventSink? = null
    private var speechRecognitionEventSink: EventChannel.EventSink? = null
    private var pendingRecordAudioPermissionResult: MethodChannel.Result? = null
    private var speechRecognitionDownloadJob: Job? = null
    private var speechRecognitionJob: Job? = null

    @Volatile
    private var isDownloadInProgress = false

    @Volatile
    private var isInferenceInProgress = false

    @Volatile
    private var isSummarizationDownloadInProgress = false

    @Volatile
    private var isRewritingDownloadInProgress = false

    @Volatile
    private var isProofreadingDownloadInProgress = false

    @Volatile
    private var isImageDescriptionDownloadInProgress = false

    @Volatile
    private var isSpeechRecognitionDownloadInProgress = false

    @Volatile
    private var isSpeechRecognitionInProgress = false

    private var totalDownloadBytes: Long? = null
    private var totalSummarizationDownloadBytes: Long? = null
    private var totalRewritingDownloadBytes: Long? = null
    private var totalProofreadingDownloadBytes: Long? = null
    private var totalImageDescriptionDownloadBytes: Long? = null
    private var totalSpeechRecognitionDownloadBytes: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        configureGenerativeModel(ModelReleaseStage.STABLE, "STABLE")
        configureSummarizer()
        configureRewriter()
        configureProofreader()
        configureImageDescriber()
        configureSpeechRecognizer()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_PROMPT_STATUS -> checkPromptStatus(result)
                METHOD_GET_MEMORY_SNAPSHOT -> getMemorySnapshot(result)
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
                METHOD_GET_REWRITING_STATUS -> checkRewritingStatus(result)
                METHOD_START_REWRITING_DOWNLOAD ->
                    startRewritingDownload(result)
                METHOD_RUN_REWRITING ->
                    runRewriting(
                        call.argument<String>("text"),
                        result,
                    )
                METHOD_GET_PROOFREADING_STATUS ->
                    checkProofreadingStatus(result)
                METHOD_START_PROOFREADING_DOWNLOAD ->
                    startProofreadingDownload(result)
                METHOD_RUN_PROOFREADING ->
                    runProofreading(
                        call.argument<String>("text"),
                        result,
                    )
                METHOD_GET_IMAGE_DESCRIPTION_STATUS ->
                    checkImageDescriptionStatus(result)
                METHOD_START_IMAGE_DESCRIPTION_DOWNLOAD ->
                    startImageDescriptionDownload(result)
                METHOD_GET_IMAGE_DESCRIPTION_TEST_IMAGE ->
                    getImageDescriptionTestImage(
                        call.argument<String>("imageId"),
                        result,
                    )
                METHOD_RUN_IMAGE_DESCRIPTION ->
                    runImageDescription(
                        call.argument<String>("imageId"),
                        result,
                    )
                METHOD_GET_SPEECH_RECOGNITION_STATUS ->
                    checkSpeechRecognitionStatus(result)
                METHOD_START_SPEECH_RECOGNITION_DOWNLOAD ->
                    startSpeechRecognitionDownload(result)
                METHOD_REQUEST_SPEECH_RECOGNITION_PERMISSION ->
                    requestSpeechRecognitionPermission(result)
                METHOD_START_SPEECH_RECOGNITION ->
                    startSpeechRecognition(result)
                METHOD_STOP_SPEECH_RECOGNITION ->
                    stopSpeechRecognition(result)
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

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REWRITING_DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    rewritingDownloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    rewritingDownloadEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PROOFREADING_DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    proofreadingDownloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    proofreadingDownloadEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IMAGE_DESCRIPTION_DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    imageDescriptionDownloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    imageDescriptionDownloadEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SPEECH_RECOGNITION_DOWNLOAD_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    speechRecognitionDownloadEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    speechRecognitionDownloadEventSink = null
                }
            },
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SPEECH_RECOGNITION_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?,
                ) {
                    speechRecognitionEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    speechRecognitionEventSink = null
                }
            },
        )
    }

    private fun getMemorySnapshot(result: MethodChannel.Result) {
        try {
            val activityManager =
                getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val systemMemory = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(systemMemory)

            val processMemory = Debug.MemoryInfo()
            Debug.getMemoryInfo(processMemory)
            val processState = ActivityManager.RunningAppProcessInfo()
            ActivityManager.getMyMemoryState(processState)

            val batteryIntent = registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )
            val batteryLevel = batteryIntent?.getIntExtra(
                BatteryManager.EXTRA_LEVEL,
                -1,
            ) ?: -1
            val batteryScale = batteryIntent?.getIntExtra(
                BatteryManager.EXTRA_SCALE,
                -1,
            ) ?: -1
            val batteryTemperatureTenthsCelsius = batteryIntent?.getIntExtra(
                BatteryManager.EXTRA_TEMPERATURE,
                -1,
            ) ?: -1
            val batteryPercent = if (batteryLevel >= 0 && batteryScale > 0) {
                batteryLevel.toDouble() * 100.0 / batteryScale.toDouble()
            } else {
                null
            }
            val batteryTemperatureCelsius =
                if (batteryTemperatureTenthsCelsius >= 0) {
                    batteryTemperatureTenthsCelsius / 10.0
                } else {
                    null
                }

            val powerManager =
                getSystemService(Context.POWER_SERVICE) as PowerManager
            val thermalStatus = if (Build.VERSION.SDK_INT >= 29) {
                powerManager.currentThermalStatus
            } else {
                null
            }
            val freeMemoryBytes = if (Build.VERSION.SDK_INT >= 37) {
                runCatching {
                    systemMemory.javaClass
                        .getField("freeMem")
                        .getLong(systemMemory)
                }.getOrNull()
            } else {
                null
            }

            val memoryStats = processMemory.memoryStats
            result.success(
                mapOf(
                    "capturedAtEpochMilliseconds" to
                        System.currentTimeMillis(),
                    "elapsedRealtimeMilliseconds" to
                        SystemClock.elapsedRealtime(),
                    "pid" to Process.myPid(),
                    "device" to mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "device" to Build.DEVICE,
                        "hardware" to Build.HARDWARE,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkLevel" to Build.VERSION.SDK_INT,
                        "buildFingerprint" to Build.FINGERPRINT,
                    ),
                    "system" to mapOf(
                        "advertisedMemoryBytes" to
                            if (Build.VERSION.SDK_INT >= 34) {
                                systemMemory.advertisedMem
                            } else {
                                null
                            },
                        "totalMemoryBytes" to systemMemory.totalMem,
                        "availableMemoryBytes" to systemMemory.availMem,
                        "freeMemoryBytes" to freeMemoryBytes,
                        "lowMemoryThresholdBytes" to systemMemory.threshold,
                        "lowMemory" to systemMemory.lowMemory,
                    ),
                    "process" to mapOf(
                        "totalPssKib" to processMemory.totalPss,
                        "totalRssKib" to
                            if (Build.VERSION.SDK_INT >= 35) {
                                Debug.getRss()
                            } else {
                                null
                            },
                        "totalPrivateDirtyKib" to
                            processMemory.totalPrivateDirty,
                        "totalPrivateCleanKib" to
                            processMemory.totalPrivateClean,
                        "totalSharedDirtyKib" to
                            processMemory.totalSharedDirty,
                        "totalSharedCleanKib" to
                            processMemory.totalSharedClean,
                        "totalSwappablePssKib" to
                            processMemory.totalSwappablePss,
                        "nativeHeapAllocatedBytes" to
                            Debug.getNativeHeapAllocatedSize(),
                        "nativeHeapSizeBytes" to Debug.getNativeHeapSize(),
                        "importance" to processState.importance,
                        "lastTrimLevel" to processState.lastTrimLevel,
                        "memoryStatsKib" to memoryStats,
                    ),
                    "environment" to mapOf(
                        "batteryPercent" to batteryPercent,
                        "batteryTemperatureCelsius" to
                            batteryTemperatureCelsius,
                        "thermalStatus" to thermalStatus,
                    ),
                ),
            )
        } catch (error: Exception) {
            result.error(
                "MEMORY_SNAPSHOT_FAILED",
                error.message ?: "Memory snapshot capture failed.",
                null,
            )
        }
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

    private fun configureRewriter() {
        val options =
            RewriterOptions.builder(this)
                .setOutputType(RewriterOptions.OutputType.PROFESSIONAL)
                .setLanguage(RewriterOptions.Language.ENGLISH)
                .build()

        rewriter = Rewriting.getClient(options)
    }

    private fun configureProofreader() {
        val options =
            ProofreaderOptions.builder(this)
                .setInputType(ProofreaderOptions.InputType.KEYBOARD)
                .setLanguage(ProofreaderOptions.Language.ENGLISH)
                .build()

        proofreader = Proofreading.getClient(options)
    }

    private fun configureImageDescriber() {
        val options = ImageDescriberOptions.builder(this).build()
        imageDescriber = ImageDescription.getClient(options)
    }

    private fun configureSpeechRecognizer() {
        val options =
            speechRecognizerOptions {
                locale = Locale.US
                preferredMode = SpeechRecognizerOptions.Mode.MODE_ADVANCED
            }

        speechRecognizer = SpeechRecognition.getClient(options)
    }

    private fun setModelReleaseStage(
        requestedStage: String?,
        result: MethodChannel.Result,
    ) {
        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
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
        if (
                isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
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
        if (
                isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
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

    private fun checkRewritingStatus(result: MethodChannel.Result) {
        val statusFuture = rewriter.checkFeatureStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    result.success(createRewritingStatusResult(statusFuture.get()))
                } catch (error: Exception) {
                    sendRewritingStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun startRewritingDownload(result: MethodChannel.Result) {
        if (
                isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano download is already running.",
                null,
            )
            return
        }

        if (rewritingDownloadEventSink == null) {
            result.error(
                "REWRITING_DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive rewriting download progress.",
                null,
            )
            return
        }

        isRewritingDownloadInProgress = true
        totalRewritingDownloadBytes = null

        try {
            rewriter.downloadFeature(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) {
                        totalRewritingDownloadBytes = bytesToDownload

                        sendRewritingDownloadEvent(
                            mapOf(
                                "event" to "started",
                                "totalBytes" to bytesToDownload,
                            ),
                        )
                    }

                    override fun onDownloadProgress(totalBytesDownloaded: Long) {
                        sendRewritingDownloadEvent(
                            mapOf(
                                "event" to "progress",
                                "downloadedBytes" to totalBytesDownloaded,
                                "totalBytes" to totalRewritingDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadCompleted() {
                        isRewritingDownloadInProgress = false

                        sendRewritingDownloadEvent(
                            mapOf(
                                "event" to "completed",
                                "downloadedBytes" to totalRewritingDownloadBytes,
                                "totalBytes" to totalRewritingDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadFailed(e: GenAiException) {
                        isRewritingDownloadInProgress = false

                        sendRewritingDownloadEvent(
                            mapOf(
                                "event" to "failed",
                                "message" to
                                    (e.message ?: "Rewriting asset download failed."),
                                "errorCode" to e.errorCode,
                            ),
                        )
                    }
                },
            )

            result.success(mapOf("started" to true))
        } catch (error: Exception) {
            isRewritingDownloadInProgress = false

            result.error(
                "REWRITING_DOWNLOAD_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun runRewriting(
        text: String?,
        result: MethodChannel.Result,
    ) {
        if (text.isNullOrBlank()) {
            result.error(
                "INVALID_REWRITING_INPUT",
                "Enter text before starting rewriting.",
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
            val request = RewritingRequest.builder(text).build()
            val inferenceFuture = rewriter.runInference(request)
            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        val suggestions = inferenceFuture.get().results
                        val output = suggestions.first().text
                        isInferenceInProgress = false

                        result.success(
                            mapOf(
                                "input" to text,
                                "output" to output,
                                "suggestionCount" to suggestions.size,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    } catch (error: Exception) {
                        isInferenceInProgress = false
                        sendRewritingInferenceError(result, error, startedAt)
                    }
                },
                mainExecutor,
            )
        } catch (error: Exception) {
            isInferenceInProgress = false
            sendRewritingInferenceError(result, error, startedAt)
        }
    }

    private fun checkProofreadingStatus(result: MethodChannel.Result) {
        val statusFuture = proofreader.checkFeatureStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    result.success(createProofreadingStatusResult(statusFuture.get()))
                } catch (error: Exception) {
                    sendProofreadingStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun startProofreadingDownload(result: MethodChannel.Result) {
        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano download is already running.",
                null,
            )
            return
        }

        if (proofreadingDownloadEventSink == null) {
            result.error(
                "PROOFREADING_DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive proofreading download progress.",
                null,
            )
            return
        }

        isProofreadingDownloadInProgress = true
        totalProofreadingDownloadBytes = null

        try {
            proofreader.downloadFeature(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) {
                        totalProofreadingDownloadBytes = bytesToDownload

                        sendProofreadingDownloadEvent(
                            mapOf(
                                "event" to "started",
                                "totalBytes" to bytesToDownload,
                            ),
                        )
                    }

                    override fun onDownloadProgress(totalBytesDownloaded: Long) {
                        sendProofreadingDownloadEvent(
                            mapOf(
                                "event" to "progress",
                                "downloadedBytes" to totalBytesDownloaded,
                                "totalBytes" to totalProofreadingDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadCompleted() {
                        isProofreadingDownloadInProgress = false

                        sendProofreadingDownloadEvent(
                            mapOf(
                                "event" to "completed",
                                "downloadedBytes" to totalProofreadingDownloadBytes,
                                "totalBytes" to totalProofreadingDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadFailed(e: GenAiException) {
                        isProofreadingDownloadInProgress = false

                        sendProofreadingDownloadEvent(
                            mapOf(
                                "event" to "failed",
                                "message" to
                                    (e.message ?: "Proofreading asset download failed."),
                                "errorCode" to e.errorCode,
                            ),
                        )
                    }
                },
            )

            result.success(mapOf("started" to true))
        } catch (error: Exception) {
            isProofreadingDownloadInProgress = false

            result.error(
                "PROOFREADING_DOWNLOAD_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun runProofreading(
        text: String?,
        result: MethodChannel.Result,
    ) {
        if (text.isNullOrBlank()) {
            result.error(
                "INVALID_PROOFREADING_INPUT",
                "Enter text before starting proofreading.",
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
            val request = ProofreadingRequest.builder(text).build()
            val inferenceFuture = proofreader.runInference(request)
            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        val suggestions = inferenceFuture.get().results
                        val output = suggestions.first().text
                        isInferenceInProgress = false

                        result.success(
                            mapOf(
                                "input" to text,
                                "output" to output,
                                "suggestionCount" to suggestions.size,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    } catch (error: Exception) {
                        isInferenceInProgress = false
                        sendProofreadingInferenceError(result, error, startedAt)
                    }
                },
                mainExecutor,
            )
        } catch (error: Exception) {
            isInferenceInProgress = false
            sendProofreadingInferenceError(result, error, startedAt)
        }
    }

    private fun checkImageDescriptionStatus(result: MethodChannel.Result) {
        val statusFuture = imageDescriber.checkFeatureStatus()
        val mainExecutor = Executor { command -> runOnUiThread(command) }

        statusFuture.addListener(
            {
                try {
                    result.success(
                        createImageDescriptionStatusResult(statusFuture.get()),
                    )
                } catch (error: Exception) {
                    sendImageDescriptionStatusError(result, error)
                }
            },
            mainExecutor,
        )
    }

    private fun startImageDescriptionDownload(result: MethodChannel.Result) {
        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano download is already running.",
                null,
            )
            return
        }

        if (imageDescriptionDownloadEventSink == null) {
            result.error(
                "IMAGE_DESCRIPTION_DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive image-description download progress.",
                null,
            )
            return
        }

        isImageDescriptionDownloadInProgress = true
        totalImageDescriptionDownloadBytes = null

        try {
            imageDescriber.downloadFeature(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) {
                        totalImageDescriptionDownloadBytes = bytesToDownload

                        sendImageDescriptionDownloadEvent(
                            mapOf(
                                "event" to "started",
                                "totalBytes" to bytesToDownload,
                            ),
                        )
                    }

                    override fun onDownloadProgress(totalBytesDownloaded: Long) {
                        sendImageDescriptionDownloadEvent(
                            mapOf(
                                "event" to "progress",
                                "downloadedBytes" to totalBytesDownloaded,
                                "totalBytes" to totalImageDescriptionDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadCompleted() {
                        isImageDescriptionDownloadInProgress = false

                        sendImageDescriptionDownloadEvent(
                            mapOf(
                                "event" to "completed",
                                "downloadedBytes" to totalImageDescriptionDownloadBytes,
                                "totalBytes" to totalImageDescriptionDownloadBytes,
                            ),
                        )
                    }

                    override fun onDownloadFailed(e: GenAiException) {
                        isImageDescriptionDownloadInProgress = false

                        sendImageDescriptionDownloadEvent(
                            mapOf(
                                "event" to "failed",
                                "message" to
                                    (e.message ?: "Image-description asset download failed."),
                                "errorCode" to e.errorCode,
                            ),
                        )
                    }
                },
            )

            result.success(mapOf("started" to true))
        } catch (error: Exception) {
            isImageDescriptionDownloadInProgress = false

            result.error(
                "IMAGE_DESCRIPTION_DOWNLOAD_START_FAILED",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    private fun getImageDescriptionTestImage(
        imageId: String?,
        result: MethodChannel.Result,
    ) {
        val selectedImageId = imageId ?: SYNTHETIC_IMAGE_ID
        if (!isSupportedImageDescriptionTestImage(selectedImageId)) {
            result.error(
                "INVALID_TEST_IMAGE",
                "Select a recognized image-description test image.",
                null,
            )
            return
        }

        val bitmap =
            try {
                createImageDescriptionTestBitmap(selectedImageId)
            } catch (error: Exception) {
                result.error(
                    "TEST_IMAGE_CREATION_FAILED",
                    error.message ?: error.toString(),
                    null,
                )
                return
            }

        try {
            val outputStream = ByteArrayOutputStream()
            val compressed =
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)

            if (!compressed) {
                result.error(
                    "TEST_IMAGE_ENCODING_FAILED",
                    "The fixed image-description test scene could not be encoded.",
                    null,
                )
                return
            }

            result.success(
                mapOf(
                    "imageBytes" to outputStream.toByteArray(),
                    "imageId" to selectedImageId,
                    "width" to bitmap.width,
                    "height" to bitmap.height,
                ),
            )
        } catch (error: Exception) {
            result.error(
                "TEST_IMAGE_CREATION_FAILED",
                error.message ?: error.toString(),
                null,
            )
        } finally {
            bitmap.recycle()
        }
    }

    private fun runImageDescription(
        imageId: String?,
        result: MethodChannel.Result,
    ) {
        val selectedImageId = imageId ?: SYNTHETIC_IMAGE_ID
        if (!isSupportedImageDescriptionTestImage(selectedImageId)) {
            result.error(
                "INVALID_TEST_IMAGE",
                "Select a recognized image-description test image.",
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
        val bitmap =
            try {
                createImageDescriptionTestBitmap(selectedImageId)
            } catch (error: Exception) {
                isInferenceInProgress = false
                sendImageDescriptionInferenceError(result, error, startedAt)
                return
            }

        try {
            val request = ImageDescriptionRequest.builder(bitmap).build()
            val inferenceFuture = imageDescriber.runInference(request)
            val mainExecutor = Executor { command -> runOnUiThread(command) }

            inferenceFuture.addListener(
                {
                    try {
                        val output = inferenceFuture.get().description
                        isInferenceInProgress = false

                        result.success(
                            mapOf(
                                "imageId" to selectedImageId,
                                "width" to bitmap.width,
                                "height" to bitmap.height,
                                "output" to output,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    } catch (error: Exception) {
                        isInferenceInProgress = false
                        sendImageDescriptionInferenceError(result, error, startedAt)
                    } finally {
                        bitmap.recycle()
                    }
                },
                mainExecutor,
            )
        } catch (error: Exception) {
            isInferenceInProgress = false
            bitmap.recycle()
            sendImageDescriptionInferenceError(result, error, startedAt)
        }
    }

    private fun checkSpeechRecognitionStatus(result: MethodChannel.Result) {
        speechCoroutineScope.launch {
            try {
                val status = speechRecognizer.checkStatus()
                runOnUiThread {
                    result.success(createSpeechRecognitionStatusResult(status))
                }
            } catch (error: Exception) {
                runOnUiThread {
                    sendSpeechRecognitionStatusError(result, error)
                }
            }
        }
    }

    private fun startSpeechRecognitionDownload(result: MethodChannel.Result) {
        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
            result.error(
                "DOWNLOAD_ALREADY_RUNNING",
                "A Gemini Nano operation is already running.",
                null,
            )
            return
        }

        if (speechRecognitionDownloadEventSink == null) {
            result.error(
                "SPEECH_RECOGNITION_DOWNLOAD_LISTENER_MISSING",
                "Flutter is not ready to receive speech-recognition download progress.",
                null,
            )
            return
        }

        isInferenceInProgress = true
        isSpeechRecognitionDownloadInProgress = true
        totalSpeechRecognitionDownloadBytes = null

        speechRecognitionDownloadJob =
            speechCoroutineScope.launch {
                try {
                    speechRecognizer.download().collect { status ->
                        when (status) {
                            is DownloadStatus.DownloadStarted -> {
                                totalSpeechRecognitionDownloadBytes =
                                    status.bytesToDownload
                                sendSpeechRecognitionDownloadEvent(
                                    mapOf(
                                        "event" to "started",
                                        "totalBytes" to status.bytesToDownload,
                                    ),
                                )
                            }

                            is DownloadStatus.DownloadProgress -> {
                                sendSpeechRecognitionDownloadEvent(
                                    mapOf(
                                        "event" to "progress",
                                        "downloadedBytes" to
                                            status.totalBytesDownloaded,
                                        "totalBytes" to
                                            totalSpeechRecognitionDownloadBytes,
                                    ),
                                )
                            }

                            is DownloadStatus.DownloadCompleted -> {
                                isSpeechRecognitionDownloadInProgress = false
                                sendSpeechRecognitionDownloadEvent(
                                    mapOf(
                                        "event" to "completed",
                                        "downloadedBytes" to
                                            totalSpeechRecognitionDownloadBytes,
                                        "totalBytes" to
                                            totalSpeechRecognitionDownloadBytes,
                                    ),
                                )
                            }

                            is DownloadStatus.DownloadFailed -> {
                                isSpeechRecognitionDownloadInProgress = false
                                sendSpeechRecognitionDownloadFailure(status.e)
                            }
                        }
                    }
                } catch (_: CancellationException) {
                    isSpeechRecognitionDownloadInProgress = false
                    isInferenceInProgress = false
                } catch (error: Exception) {
                    isSpeechRecognitionDownloadInProgress = false
                    isInferenceInProgress = false
                    sendSpeechRecognitionDownloadFailure(error)
                } finally {
                    isSpeechRecognitionDownloadInProgress = false
                    isInferenceInProgress = false
                    speechRecognitionDownloadJob = null
                }
            }

        result.success(mapOf("started" to true))
    }

    private fun requestSpeechRecognitionPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(mapOf("granted" to true))
            return
        }

        if (pendingRecordAudioPermissionResult != null) {
            result.error(
                "RECORD_AUDIO_PERMISSION_PENDING",
                "The microphone permission request is already open.",
                null,
            )
            return
        }

        pendingRecordAudioPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            RECORD_AUDIO_PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != RECORD_AUDIO_PERMISSION_REQUEST_CODE) {
            return
        }

        val permissionResult = pendingRecordAudioPermissionResult
        pendingRecordAudioPermissionResult = null
        val granted =
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

        permissionResult?.success(
            mapOf(
                "granted" to granted,
                "canAskAgain" to
                    shouldShowRequestPermissionRationale(
                        Manifest.permission.RECORD_AUDIO,
                    ),
            ),
        )
    }

    private fun startSpeechRecognition(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                "RECORD_AUDIO_PERMISSION_REQUIRED",
                "Microphone permission is required for this test.",
                null,
            )
            return
        }

        if (speechRecognitionEventSink == null) {
            result.error(
                "SPEECH_RECOGNITION_LISTENER_MISSING",
                "Flutter is not ready to receive speech-recognition results.",
                null,
            )
            return
        }

        if (
            isInferenceInProgress ||
                isDownloadInProgress ||
                isSummarizationDownloadInProgress ||
                isRewritingDownloadInProgress ||
                isProofreadingDownloadInProgress ||
                isImageDescriptionDownloadInProgress ||
                isSpeechRecognitionDownloadInProgress
        ) {
            result.error(
                "INFERENCE_ALREADY_RUNNING",
                "A Gemini Nano operation is already running.",
                null,
            )
            return
        }

        isInferenceInProgress = true
        isSpeechRecognitionInProgress = true
        val startedAt = SystemClock.elapsedRealtime()

        sendSpeechRecognitionEvent(
            mapOf(
                "event" to "started",
                "mode" to "ADVANCED",
                "locale" to "en-US",
                "elapsedMilliseconds" to 0L,
            ),
        )

        speechRecognitionJob =
            speechCoroutineScope.launch {
                var finalTranscript = ""
                var terminalResponseReceived = false

                try {
                    val request =
                        speechRecognizerRequest {
                            audioSource = AudioSource.fromMic()
                        }

                    speechRecognizer.startRecognition(request).collect { response ->
                        if (terminalResponseReceived) {
                            return@collect
                        }

                        val elapsedMilliseconds =
                            SystemClock.elapsedRealtime() - startedAt

                        when (response) {
                            is SpeechRecognizerResponse.PartialTextResponse -> {
                                sendSpeechRecognitionEvent(
                                    mapOf(
                                        "event" to "partial",
                                        "text" to response.text,
                                        "finalText" to finalTranscript,
                                        "elapsedMilliseconds" to elapsedMilliseconds,
                                    ),
                                )
                            }

                            is SpeechRecognizerResponse.FinalTextResponse -> {
                                finalTranscript =
                                    "${finalTranscript.trim()} ${response.text.trim()}".trim()
                                sendSpeechRecognitionEvent(
                                    mapOf(
                                        "event" to "final",
                                        "text" to response.text,
                                        "finalText" to finalTranscript,
                                        "elapsedMilliseconds" to elapsedMilliseconds,
                                    ),
                                )
                            }

                            is SpeechRecognizerResponse.CompletedResponse -> {
                                terminalResponseReceived = true
                                finishSpeechRecognition()
                                sendSpeechRecognitionEvent(
                                    mapOf(
                                        "event" to "completed",
                                        "finalText" to finalTranscript,
                                        "elapsedMilliseconds" to elapsedMilliseconds,
                                    ),
                                )
                            }

                            is SpeechRecognizerResponse.ErrorResponse -> {
                                terminalResponseReceived = true
                                finishSpeechRecognition()
                                sendSpeechRecognitionFailure(
                                    response.e,
                                    finalTranscript,
                                    startedAt,
                                )
                            }
                        }
                    }

                    if (!terminalResponseReceived) {
                        finishSpeechRecognition()
                        sendSpeechRecognitionEvent(
                            mapOf(
                                "event" to "completed",
                                "finalText" to finalTranscript,
                                "elapsedMilliseconds" to
                                    SystemClock.elapsedRealtime() - startedAt,
                            ),
                        )
                    }
                } catch (_: CancellationException) {
                    finishSpeechRecognition()
                } catch (error: Exception) {
                    finishSpeechRecognition()
                    sendSpeechRecognitionFailure(
                        error,
                        finalTranscript,
                        startedAt,
                    )
                } finally {
                    speechRecognitionJob = null
                }
            }

        result.success(
            mapOf(
                "started" to true,
                "mode" to "ADVANCED",
                "locale" to "en-US",
            ),
        )
    }

    private fun stopSpeechRecognition(result: MethodChannel.Result) {
        if (!isSpeechRecognitionInProgress) {
            result.success(mapOf("stopping" to false))
            return
        }

        sendSpeechRecognitionEvent(mapOf("event" to "stopping"))

        speechCoroutineScope.launch {
            try {
                speechRecognizer.stopRecognition()
                runOnUiThread {
                    result.success(mapOf("stopping" to true))
                }
            } catch (error: Exception) {
                runOnUiThread {
                    val cause = unwrapExecutionError(error)
                    result.error(
                        "SPEECH_RECOGNITION_STOP_FAILED",
                        cause.message ?: cause.toString(),
                        null,
                    )
                }
            }
        }
    }

    private fun finishSpeechRecognition() {
        isSpeechRecognitionInProgress = false
        isInferenceInProgress = false
    }

    private fun isSupportedImageDescriptionTestImage(imageId: String): Boolean {
        return imageId == SYNTHETIC_IMAGE_ID || imageId == REAL_PHOTO_IMAGE_ID
    }

    private fun createImageDescriptionTestBitmap(imageId: String): Bitmap {
        return when (imageId) {
            SYNTHETIC_IMAGE_ID -> createSyntheticImageDescriptionTestBitmap()
            REAL_PHOTO_IMAGE_ID ->
                BitmapFactory.decodeResource(
                    resources,
                    R.drawable.nano_lab_real_tabletop_photo_v1,
                ) ?: throw IllegalStateException(
                    "The bundled real tabletop photo could not be decoded.",
                )
            else -> throw IllegalArgumentException("Unknown test image: $imageId")
        }
    }

    private fun createSyntheticImageDescriptionTestBitmap(): Bitmap {
        val bitmap =
            Bitmap.createBitmap(
                SYNTHETIC_IMAGE_WIDTH,
                SYNTHETIC_IMAGE_HEIGHT,
                Bitmap.Config.ARGB_8888,
            )
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        canvas.drawColor(Color.rgb(135, 206, 235))

        paint.color = Color.rgb(76, 175, 80)
        canvas.drawRect(0f, 350f, 768f, 512f, paint)

        paint.color = Color.rgb(255, 214, 0)
        canvas.drawCircle(650f, 85f, 50f, paint)

        paint.color = Color.WHITE
        canvas.drawCircle(100f, 90f, 28f, paint)
        canvas.drawCircle(135f, 75f, 38f, paint)
        canvas.drawCircle(175f, 92f, 30f, paint)
        canvas.drawCircle(500f, 120f, 24f, paint)
        canvas.drawCircle(532f, 105f, 34f, paint)
        canvas.drawCircle(568f, 122f, 26f, paint)

        paint.color = Color.rgb(198, 40, 40)
        canvas.drawRect(140f, 220f, 430f, 420f, paint)

        paint.color = Color.rgb(93, 64, 55)
        val roof = Path()
        roof.moveTo(110f, 230f)
        roof.lineTo(285f, 95f)
        roof.lineTo(460f, 230f)
        roof.close()
        canvas.drawPath(roof, paint)

        paint.color = Color.rgb(30, 136, 229)
        canvas.drawRect(255f, 315f, 325f, 420f, paint)

        paint.color = Color.rgb(255, 235, 59)
        canvas.drawRect(175f, 265f, 230f, 320f, paint)
        canvas.drawRect(345f, 265f, 400f, 320f, paint)

        paint.color = Color.rgb(62, 39, 35)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 7f
        canvas.drawRect(175f, 265f, 230f, 320f, paint)
        canvas.drawRect(345f, 265f, 400f, 320f, paint)
        paint.style = Paint.Style.FILL

        paint.color = Color.rgb(121, 85, 72)
        canvas.drawRect(530f, 285f, 565f, 420f, paint)

        paint.color = Color.rgb(27, 121, 55)
        canvas.drawCircle(548f, 250f, 72f, paint)
        canvas.drawCircle(505f, 275f, 52f, paint)
        canvas.drawCircle(592f, 275f, 52f, paint)

        return bitmap
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

    private fun sendRewritingDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            rewritingDownloadEventSink?.success(event)
        }
    }

    private fun sendProofreadingDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            proofreadingDownloadEventSink?.success(event)
        }
    }

    private fun sendImageDescriptionDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            imageDescriptionDownloadEventSink?.success(event)
        }
    }

    private fun sendSpeechRecognitionDownloadEvent(event: Map<String, Any?>) {
        runOnUiThread {
            speechRecognitionDownloadEventSink?.success(event)
        }
    }

    private fun sendSpeechRecognitionEvent(event: Map<String, Any?>) {
        runOnUiThread {
            speechRecognitionEventSink?.success(event)
        }
    }

    private fun sendSpeechRecognitionDownloadFailure(error: Exception) {
        val cause = unwrapExecutionError(error)
        val event =
            if (cause is GenAiException) {
                mapOf(
                    "event" to "failed",
                    "message" to
                        (cause.message ?: "Speech-recognition asset download failed."),
                    "errorCode" to cause.errorCode,
                )
            } else {
                mapOf(
                    "event" to "failed",
                    "message" to (cause.message ?: cause.toString()),
                )
            }

        sendSpeechRecognitionDownloadEvent(event)
    }

    private fun sendSpeechRecognitionFailure(
        error: Exception,
        finalTranscript: String,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)
        val elapsedMilliseconds = SystemClock.elapsedRealtime() - startedAt
        val event =
            if (cause is GenAiException) {
                mapOf(
                    "event" to "failed",
                    "message" to
                        (cause.message ?: "Speech recognition failed."),
                    "errorCode" to cause.errorCode,
                    "finalText" to finalTranscript,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                )
            } else {
                mapOf(
                    "event" to "failed",
                    "message" to (cause.message ?: cause.toString()),
                    "finalText" to finalTranscript,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                )
            }

        sendSpeechRecognitionEvent(event)
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

    private fun sendRewritingInferenceError(
        result: MethodChannel.Result,
        error: Exception,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)
        val elapsedMilliseconds = SystemClock.elapsedRealtime() - startedAt

        if (cause is GenAiException) {
            result.error(
                "GENAI_REWRITING_${cause.errorCode}",
                cause.message ?: "Gemini Nano rewriting failed.",
                mapOf(
                    "errorCode" to cause.errorCode,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                ),
            )
        } else {
            result.error(
                "REWRITING_FAILED",
                cause.message ?: cause.toString(),
                mapOf("elapsedMilliseconds" to elapsedMilliseconds),
            )
        }
    }

    private fun sendProofreadingInferenceError(
        result: MethodChannel.Result,
        error: Exception,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)
        val elapsedMilliseconds = SystemClock.elapsedRealtime() - startedAt

        if (cause is GenAiException) {
            result.error(
                "GENAI_PROOFREADING_${cause.errorCode}",
                cause.message ?: "Gemini Nano proofreading failed.",
                mapOf(
                    "errorCode" to cause.errorCode,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                ),
            )
        } else {
            result.error(
                "PROOFREADING_FAILED",
                cause.message ?: cause.toString(),
                mapOf("elapsedMilliseconds" to elapsedMilliseconds),
            )
        }
    }

    private fun sendImageDescriptionInferenceError(
        result: MethodChannel.Result,
        error: Exception,
        startedAt: Long,
    ) {
        val cause = unwrapExecutionError(error)
        val elapsedMilliseconds = SystemClock.elapsedRealtime() - startedAt

        if (cause is GenAiException) {
            result.error(
                "GENAI_IMAGE_DESCRIPTION_${cause.errorCode}",
                cause.message ?: "Gemini Nano image description failed.",
                mapOf(
                    "errorCode" to cause.errorCode,
                    "elapsedMilliseconds" to elapsedMilliseconds,
                ),
            )
        } else {
            result.error(
                "IMAGE_DESCRIPTION_FAILED",
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

    private fun createRewritingStatusResult(status: Int): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description = "The dedicated Rewriting API is ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports rewriting, but its required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description = "The required rewriting assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "The selected English professional rewriting configuration is unavailable."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Rewriting API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
        )
    }

    private fun createProofreadingStatusResult(status: Int): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description = "The dedicated Proofreading API is ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports proofreading, but its required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description = "The required proofreading assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "The selected English keyboard proofreading configuration is unavailable."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Proofreading API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
        )
    }

    private fun createImageDescriptionStatusResult(
        status: Int,
    ): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description = "The dedicated Image Description API is ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports image description, but its required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description =
                    "The required image-description assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "The selected Image Description API configuration is unavailable."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Image Description API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
        )
    }

    private fun createSpeechRecognitionStatusResult(
        status: Int,
    ): Map<String, Any> {
        val statusName: String
        val description: String

        when (status) {
            FeatureStatus.AVAILABLE -> {
                statusName = "AVAILABLE"
                description =
                    "Advanced en-US speech recognition is ready to use."
            }

            FeatureStatus.DOWNLOADABLE -> {
                statusName = "DOWNLOADABLE"
                description =
                    "This device supports Advanced en-US speech recognition, but its required assets need to be downloaded."
            }

            FeatureStatus.DOWNLOADING -> {
                statusName = "DOWNLOADING"
                description =
                    "The required speech-recognition assets are currently downloading."
            }

            FeatureStatus.UNAVAILABLE -> {
                statusName = "UNAVAILABLE"
                description =
                    "Advanced en-US speech recognition is unavailable on this device or AICore is not ready."
            }

            else -> {
                statusName = "UNKNOWN"
                description =
                    "The Speech Recognition API returned an unrecognized status value: $status."
            }
        }

        return mapOf(
            "status" to statusName,
            "description" to description,
            "statusCode" to status,
            "mode" to "ADVANCED",
            "locale" to "en-US",
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

    private fun sendRewritingStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_REWRITING_STATUS_${cause.errorCode}",
                cause.message ?: "Rewriting status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "REWRITING_STATUS_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendProofreadingStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_PROOFREADING_STATUS_${cause.errorCode}",
                cause.message ?: "Proofreading status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "PROOFREADING_STATUS_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendImageDescriptionStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_IMAGE_DESCRIPTION_STATUS_${cause.errorCode}",
                cause.message ?: "Image-description status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "IMAGE_DESCRIPTION_STATUS_FAILED",
                cause.message ?: cause.toString(),
                null,
            )
        }
    }

    private fun sendSpeechRecognitionStatusError(
        result: MethodChannel.Result,
        error: Exception,
    ) {
        val cause = unwrapExecutionError(error)

        if (cause is GenAiException) {
            result.error(
                "GENAI_SPEECH_RECOGNITION_STATUS_${cause.errorCode}",
                cause.message ?: "Speech-recognition status detection failed.",
                mapOf("errorCode" to cause.errorCode),
            )
        } else {
            result.error(
                "SPEECH_RECOGNITION_STATUS_FAILED",
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
        rewritingDownloadEventSink = null
        proofreadingDownloadEventSink = null
        imageDescriptionDownloadEventSink = null
        speechRecognitionDownloadEventSink = null
        speechRecognitionEventSink = null
        pendingRecordAudioPermissionResult = null

        speechRecognitionJob?.cancel()
        speechRecognitionDownloadJob?.cancel()
        finishSpeechRecognition()
        isSpeechRecognitionDownloadInProgress = false

        if (::speechRecognizer.isInitialized) {
            speechRecognizer.close()
        }

        speechCoroutineScope.cancel()

        if (::generativeModel.isInitialized) {
            generativeModel.close()
        }

        if (::summarizer.isInitialized) {
            summarizer.close()
        }

        if (::rewriter.isInitialized) {
            rewriter.close()
        }

        if (::proofreader.isInitialized) {
            proofreader.close()
        }

        if (::imageDescriber.isInitialized) {
            imageDescriber.close()
        }

        super.onDestroy()
    }
}
