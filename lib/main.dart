import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NanoLabApp());
}

class NanoLabApp extends StatelessWidget {
  const NanoLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NanoStatusScreen(),
    );
  }
}

class NanoStatusScreen extends StatefulWidget {
  const NanoStatusScreen({super.key});

  @override
  State<NanoStatusScreen> createState() => _NanoStatusScreenState();
}

class _PromptRun {
  _PromptRun({
    required this.number,
    required this.prompt,
    required this.systemInstruction,
    required this.temperature,
    required this.maxOutputTokens,
    required this.seed,
    required this.topK,
    required this.candidateCount,
    required this.modelReleaseStage,
    required this.output,
    required this.candidates,
    required this.elapsedMilliseconds,
    required this.requestTokens,
    required this.tokenLimit,
    required this.finishReason,
    required this.finishReasonCode,
  });

  final int number;
  final String prompt;
  final String? systemInstruction;
  final double temperature;
  final int maxOutputTokens;
  final int seed;
  final int topK;
  final int candidateCount;
  final String modelReleaseStage;
  final String output;
  final List<Map<String, dynamic>> candidates;
  final int elapsedMilliseconds;
  final int requestTokens;
  final int tokenLimit;
  final String? finishReason;
  final int? finishReasonCode;
  String? rating;
}

class _NanoStatusScreenState extends State<NanoStatusScreen> {
  static const _nativeChannel = MethodChannel(
    'com.mycarejournals.nano_lab/native',
  );

  static const _downloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/download_events',
  );

  static const _promptChannel = EventChannel(
    'com.mycarejournals.nano_lab/prompt_events',
  );

  static const _summarizationDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/summarization_download_events',
  );

  static const _defaultPrompt =
      'Write exactly three short sentences about a fictional robot learning '
      'to garden.';

  static const _defaultSystemInstruction =
      'Respond using uppercase letters only.';

  static const _defaultSummarizationText =
      'The fictional town of Alder Cove opened a community tool library in '
      'April 2026 after residents approved a six-month trial. The library is '
      'located in a renovated room beside the town hall and is open on '
      'Tuesdays from 4:00 PM to 8:00 PM and Saturdays from 9:00 AM to 1:00 PM. '
      'Members can borrow hand tools, gardening equipment, sewing machines, '
      'and small kitchen appliances for up to seven days. Membership is free, '
      'but borrowers must be at least eighteen years old and show proof that '
      'they live in Alder Cove. During the first month, 184 residents joined '
      'and borrowed 327 items. The most frequently borrowed item was a cordless '
      'drill, followed by a hedge trimmer and a carpet cleaner. Two items were '
      'returned late, and one garden rake was returned with a broken handle. '
      'Volunteers repaired the rake using donated materials, so the town paid '
      'no repair cost. The project received a startup grant of \$12,500 from '
      'the fictional North Pine Community Fund. Organizers spent \$8,900 on '
      'equipment, \$1,600 on shelving, and \$750 on safety supplies. The '
      'remaining money was reserved for replacement parts and future '
      'purchases. Before opening, fourteen volunteers completed two evening '
      'safety workshops led by local carpenter Mara Voss. Borrowers receive a '
      'short safety guide with each power tool, and first-time users may ask '
      'for a ten-minute demonstration. Items can be reserved in person or by '
      'telephone, but the library does not accept reservations more than two '
      'weeks ahead. If another member is waiting, an item cannot be renewed. '
      'The town also placed a blue donation bin in the lobby for unused tools. '
      'By the end of May, residents had donated forty-six items, although nine '
      'were rejected because they were damaged or missing safety guards. The '
      'library tracks each loan with a paper receipt and an offline computer '
      'record. No membership information is shared outside the program. '
      'Organizers plan to add bicycle repair tools if the permanent budget is '
      'approved. A resident survey found that 86 percent of respondents wanted '
      'the trial to continue. The town council will review the program on '
      'October 12, 2026, before deciding whether to fund it permanently.';

  late final TextEditingController _promptController;
  late final TextEditingController _systemInstructionController;
  late final TextEditingController _maxOutputTokensController;
  late final TextEditingController _seedController;
  late final TextEditingController _topKController;
  late final TextEditingController _candidateCountController;
  late final TextEditingController _summarizationController;

  late final StreamSubscription<dynamic> _downloadSubscription;
  late final StreamSubscription<dynamic> _promptSubscription;
  late final StreamSubscription<dynamic> _summarizationDownloadSubscription;

  bool _isChecking = false;
  bool _isStartingDownload = false;
  bool _isRunningPrompt = false;
  bool _isCheckingSummarization = false;
  bool _isStartingSummarizationDownload = false;
  bool _isRunningSummarization = false;
  bool _systemInstructionAvailable = false;
  double _temperature = 0.0;
  String _modelReleaseStage = 'STABLE';

  String _status = 'NOT CHECKED';
  String _description =
      'Tap the button to ask AICore for the current Prompt API status.';

  String _promptStatus = 'Not run';
  String _promptOutput = '';
  List<Map<String, dynamic>> _candidates = <Map<String, dynamic>>[];
  String? _submittedPrompt;
  String? _submittedSystemInstruction;
  double? _submittedTemperature;
  int? _submittedMaxOutputTokens;
  int? _submittedSeed;
  int? _submittedTopK;
  int? _submittedCandidateCount;
  String? _finishReason;
  int? _finishReasonCode;
  final List<_PromptRun> _completedRuns = <_PromptRun>[];
  int _nextRunNumber = 1;
  int? _activeRunNumber;

  String? _deviceInformation;
  String? _systemInstructionDescription;
  String? _systemInstructionError;
  String? _errorDetails;
  String? _downloadMessage;
  String? _promptError;

  int? _downloadedBytes;
  int? _totalBytes;
  int? _elapsedMilliseconds;
  int? _requestTokens;
  int? _tokenLimit;

  String _summarizationStatus = 'NOT CHECKED';
  String _summarizationDescription =
      'Check whether the dedicated ML Kit Summarization API is available.';
  String? _summarizationError;
  String? _summarizationDownloadMessage;
  String? _submittedSummarizationInput;
  String _summarizationOutput = '';
  int? _summarizationDownloadedBytes;
  int? _summarizationTotalBytes;
  int? _summarizationElapsedMilliseconds;

  @override
  void initState() {
    super.initState();

    _promptController = TextEditingController(text: _defaultPrompt);
    _systemInstructionController = TextEditingController(
      text: _defaultSystemInstruction,
    );
    _maxOutputTokensController = TextEditingController(text: '4096');
    _seedController = TextEditingController(text: '0');
    _topKController = TextEditingController(text: '3');
    _candidateCountController = TextEditingController(text: '1');
    _summarizationController = TextEditingController(
      text: _defaultSummarizationText,
    );

    _downloadSubscription = _downloadChannel.receiveBroadcastStream().listen(
      _handleDownloadEvent,
      onError: _handleDownloadStreamError,
    );

    _promptSubscription = _promptChannel.receiveBroadcastStream().listen(
      _handlePromptEvent,
      onError: _handlePromptStreamError,
    );

    _summarizationDownloadSubscription = _summarizationDownloadChannel
        .receiveBroadcastStream()
        .listen(
          _handleSummarizationDownloadEvent,
          onError: _handleSummarizationDownloadStreamError,
        );
  }

  @override
  void dispose() {
    _downloadSubscription.cancel();
    _promptSubscription.cancel();
    _summarizationDownloadSubscription.cancel();
    _promptController.dispose();
    _systemInstructionController.dispose();
    _maxOutputTokensController.dispose();
    _seedController.dispose();
    _topKController.dispose();
    _candidateCountController.dispose();
    _summarizationController.dispose();
    super.dispose();
  }

  Future<void> _checkNanoStatus() async {
    setState(() {
      _isChecking = true;
      _status = 'CHECKING';
      _description = 'Checking Gemini Nano availability…';
      _systemInstructionAvailable = false;
      _systemInstructionDescription = null;
      _systemInstructionError = null;
      _errorDetails = null;
    });

    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'getPromptStatus',
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _status = 'ERROR';
          _description = 'Kotlin returned no status information.';
        });
        return;
      }

      final status = result['status']?.toString() ?? 'UNKNOWN';

      setState(() {
        _status = status;
        _description =
            result['description']?.toString() ??
            'No status description was returned.';
        _deviceInformation =
            '${result['manufacturer']} ${result['model']}\n'
            'Android ${result['androidVersion']} · SDK ${result['sdkLevel']}';
      });

      if (status == 'AVAILABLE') {
        await _checkSystemInstructionStatus();
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'ERROR';
        _description = error.message ?? 'Gemini Nano status detection failed.';
        _errorDetails = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'ERROR';
        _description = 'Unexpected status-check failure.';
        _errorDetails = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _setModelReleaseStage(String releaseStage) async {
    setState(() {
      _modelReleaseStage = releaseStage;
      _status = 'NOT CHECKED';
      _description = 'Check availability for the selected model stage.';
      _systemInstructionAvailable = false;
      _systemInstructionDescription = null;
      _systemInstructionError = null;
      _errorDetails = null;
    });

    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'setModelReleaseStage',
        <String, dynamic>{'modelReleaseStage': releaseStage},
      );

      if (!mounted) {
        return;
      }

      if (result?['modelReleaseStage']?.toString() != releaseStage) {
        setState(() {
          _status = 'ERROR';
          _description = 'Kotlin did not select the requested model stage.';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'ERROR';
        _description = error.message ?? 'The model stage could not be changed.';
        _errorDetails = 'Platform error: ${error.code}';
      });
    }
  }

  Future<void> _checkSystemInstructionStatus() async {
    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'getSystemInstructionStatus',
      );

      if (!mounted) {
        return;
      }

      if (result == null || result['available'] is! bool) {
        setState(() {
          _systemInstructionError =
              'Kotlin returned no system-instruction capability information.';
        });
        return;
      }

      setState(() {
        _systemInstructionAvailable = result['available'] as bool;
        _systemInstructionDescription =
            result['description']?.toString() ??
            ((result['available'] as bool)
                ? 'System instructions are supported on this device.'
                : 'System instructions are not supported on this device.');
        _systemInstructionError = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _systemInstructionError =
            '${error.message ?? 'System-instruction capability detection failed.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _systemInstructionError =
            'Unexpected system-instruction status error: $error';
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isStartingDownload = true;
      _downloadMessage = 'Requesting the Gemini Nano download…';
      _downloadedBytes = null;
      _totalBytes = null;
      _errorDetails = null;
    });

    try {
      await _nativeChannel.invokeMethod<dynamic>('startPromptDownload');

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'DOWNLOADING';
        _description = 'The required Gemini Nano assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _downloadMessage = null;
        _errorDetails =
            '${error.message ?? 'The download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _downloadMessage = null;
        _errorDetails = 'Unexpected download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingDownload = false;
        });
      }
    }
  }

  Future<void> _checkSummarizationStatus() async {
    setState(() {
      _isCheckingSummarization = true;
      _summarizationStatus = 'CHECKING';
      _summarizationDescription =
          'Checking the dedicated Summarization API configuration…';
      _summarizationError = null;
    });

    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'getSummarizationStatus',
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _summarizationStatus = 'ERROR';
          _summarizationDescription =
              'Kotlin returned no summarization status information.';
        });
        return;
      }

      setState(() {
        _summarizationStatus = result['status']?.toString() ?? 'UNKNOWN';
        _summarizationDescription =
            result['description']?.toString() ??
            'No summarization status description was returned.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationStatus = 'ERROR';
        _summarizationDescription =
            error.message ?? 'Summarization status detection failed.';
        _summarizationError = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationStatus = 'ERROR';
        _summarizationDescription =
            'Unexpected summarization status-check failure.';
        _summarizationError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSummarization = false;
        });
      }
    }
  }

  Future<void> _startSummarizationDownload() async {
    setState(() {
      _isStartingSummarizationDownload = true;
      _summarizationDownloadMessage =
          'Requesting the summarization asset download…';
      _summarizationDownloadedBytes = null;
      _summarizationTotalBytes = null;
      _summarizationError = null;
    });

    try {
      await _nativeChannel.invokeMethod<dynamic>('startSummarizationDownload');

      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationStatus = 'DOWNLOADING';
        _summarizationDescription =
            'The required summarization assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationDownloadMessage = null;
        _summarizationError =
            '${error.message ?? 'The summarization download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationDownloadMessage = null;
        _summarizationError = 'Unexpected summarization download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSummarizationDownload = false;
        });
      }
    }
  }

  Future<void> _runSummarization() async {
    final input = _summarizationController.text;
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isRunningSummarization = true;
      _submittedSummarizationInput = input;
      _summarizationOutput = '';
      _summarizationElapsedMilliseconds = null;
      _summarizationError = null;
    });

    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'runSummarization',
        <String, dynamic>{'text': input},
      );
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _summarizationElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _summarizationError = 'Kotlin returned no summarization result.';
        });
        return;
      }

      final nativeInput = result['input']?.toString();
      if (nativeInput != input) {
        setState(() {
          _summarizationElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _summarizationError =
              'The native summarization input did not match the displayed input.';
        });
        return;
      }

      setState(() {
        _summarizationOutput = result['output']?.toString() ?? '';
        _summarizationElapsedMilliseconds =
            _readInteger(result['elapsedMilliseconds']) ??
            stopwatch.elapsedMilliseconds;
      });
    } on PlatformException catch (error) {
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      final details = error.details;
      final nativeElapsedMilliseconds = details is Map
          ? _readInteger(details['elapsedMilliseconds'])
          : null;

      setState(() {
        _summarizationElapsedMilliseconds =
            nativeElapsedMilliseconds ?? stopwatch.elapsedMilliseconds;
        _summarizationError =
            '${error.message ?? 'Gemini Nano summarization failed.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _summarizationElapsedMilliseconds = stopwatch.elapsedMilliseconds;
        _summarizationError = 'Unexpected summarization error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningSummarization = false;
        });
      }
    }
  }

  Future<void> _runPrompt({_PromptRun? repeatRun}) async {
    final prompt = repeatRun?.prompt ?? _promptController.text;
    final systemInstruction = repeatRun == null
        ? _systemInstructionController.text
        : (repeatRun.systemInstruction ?? '');
    final temperature = repeatRun?.temperature ?? _temperature;
    final maxOutputTokens =
        repeatRun?.maxOutputTokens ??
        int.tryParse(_maxOutputTokensController.text);
    final seed = repeatRun?.seed ?? int.tryParse(_seedController.text);
    final topK = repeatRun?.topK ?? int.tryParse(_topKController.text);
    final candidateCount =
        repeatRun?.candidateCount ??
        int.tryParse(_candidateCountController.text);
    final systemInstructionToSend = systemInstruction.trim().isEmpty
        ? null
        : systemInstruction;

    if (repeatRun != null &&
        repeatRun.modelReleaseStage != _modelReleaseStage) {
      setState(() {
        _promptStatus = 'Error';
        _promptError =
            'Select ${repeatRun.modelReleaseStage.toLowerCase()} and check '
            'availability before repeating this run.';
      });
      return;
    }

    if (maxOutputTokens == null ||
        maxOutputTokens < 1 ||
        maxOutputTokens > 4096) {
      setState(() {
        _promptStatus = 'Error';
        _promptError =
            'Maximum output tokens must be a whole number from 1 to 4096.';
      });
      return;
    }

    if (seed == null || seed < 0 || seed > 2147483647) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Seed must be a whole number from 0 to 2147483647.';
      });
      return;
    }

    if (topK == null || topK < 1 || topK > 2147483647) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Top-K must be a whole number from 1 to 2147483647.';
      });
      return;
    }

    if (candidateCount == null || candidateCount < 1 || candidateCount > 8) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Candidate count must be a whole number from 1 to 8.';
      });
      return;
    }

    setState(() {
      _isRunningPrompt = true;
      _promptStatus = 'Starting…';
      _promptOutput = '';
      _candidates = <Map<String, dynamic>>[];
      _submittedPrompt = prompt;
      _submittedSystemInstruction = systemInstructionToSend;
      _submittedTemperature = temperature;
      _submittedMaxOutputTokens = maxOutputTokens;
      _submittedSeed = seed;
      _submittedTopK = topK;
      _submittedCandidateCount = candidateCount;
      _promptError = null;
      _elapsedMilliseconds = null;
      _requestTokens = null;
      _tokenLimit = null;
      _finishReason = null;
      _finishReasonCode = null;
    });

    try {
      final tokenResult = await _nativeChannel
          .invokeMapMethod<String, dynamic>('getTokenInfo', <String, dynamic>{
            'prompt': prompt,
            'systemInstruction': systemInstruction,
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
            'seed': seed,
            'topK': topK,
            'candidateCount': candidateCount,
            'modelReleaseStage': _modelReleaseStage,
          });

      if (!mounted) {
        return;
      }

      if (tokenResult == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned no token information.';
        });
        return;
      }

      final nativeTokenPrompt = tokenResult['prompt']?.toString();
      final nativeTokenSystemInstruction = tokenResult['systemInstruction']
          ?.toString();
      final nativeTokenTemperature = tokenResult['temperature'];
      final nativeTokenMaxOutputTokens = _readInteger(
        tokenResult['maxOutputTokens'],
      );
      final nativeTokenSeed = _readInteger(tokenResult['seed']);
      final nativeTokenTopK = _readInteger(tokenResult['topK']);
      final nativeTokenCandidateCount = _readInteger(
        tokenResult['candidateCount'],
      );

      if (nativeTokenPrompt != prompt ||
          nativeTokenSystemInstruction != systemInstructionToSend ||
          nativeTokenTemperature is! double ||
          nativeTokenTemperature != temperature ||
          nativeTokenMaxOutputTokens != maxOutputTokens ||
          nativeTokenSeed != seed ||
          nativeTokenTopK != topK ||
          nativeTokenCandidateCount != candidateCount) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError =
              'The token-count request did not match the displayed instructions.';
        });
        return;
      }

      final requestTokens = _readInteger(tokenResult['requestTokens']);
      final tokenLimit = _readInteger(tokenResult['tokenLimit']);

      if (requestTokens == null || tokenLimit == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned incomplete token information.';
        });
        return;
      }

      setState(() {
        _requestTokens = requestTokens;
        _tokenLimit = tokenLimit;
        _activeRunNumber = _nextRunNumber;
        _nextRunNumber++;
      });

      final result = await _nativeChannel
          .invokeMapMethod<String, dynamic>('runPrompt', <String, dynamic>{
            'prompt': prompt,
            'systemInstruction': systemInstruction,
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
            'seed': seed,
            'topK': topK,
            'candidateCount': candidateCount,
            'modelReleaseStage': _modelReleaseStage,
          });

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned no inference-start information.';
        });
        return;
      }

      final nativePrompt = result['prompt']?.toString();
      final nativeSystemInstruction = result['systemInstruction']?.toString();
      final nativeTemperature = result['temperature'];
      final nativeMaxOutputTokens = _readInteger(result['maxOutputTokens']);
      final nativeSeed = _readInteger(result['seed']);
      final nativeTopK = _readInteger(result['topK']);
      final nativeCandidateCount = _readInteger(result['candidateCount']);

      if (nativePrompt != prompt ||
          nativeSystemInstruction != systemInstructionToSend ||
          nativeTemperature is! double ||
          nativeTemperature != temperature ||
          nativeMaxOutputTokens != maxOutputTokens ||
          nativeSeed != seed ||
          nativeTopK != topK ||
          nativeCandidateCount != candidateCount) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError =
              'The native request did not match the displayed instructions.';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunningPrompt = false;
        _promptStatus = 'Error';
        _promptError =
            '${error.message ?? 'Token counting or Gemini Nano inference could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRunningPrompt = false;
        _promptStatus = 'Error';
        _promptError = 'Unexpected inference error: $error';
      });
    }
  }

  void _clearPromptOutput() {
    setState(() {
      _promptStatus = 'Not run';
      _promptOutput = '';
      _submittedPrompt = null;
      _submittedSystemInstruction = null;
      _submittedTemperature = null;
      _submittedMaxOutputTokens = null;
      _submittedSeed = null;
      _submittedTopK = null;
      _submittedCandidateCount = null;
      _candidates = <Map<String, dynamic>>[];
      _promptError = null;
      _elapsedMilliseconds = null;
      _requestTokens = null;
      _tokenLimit = null;
      _finishReason = null;
      _finishReasonCode = null;
    });
  }

  void _handleDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _status = 'DOWNLOADING';
          _description = 'The required Gemini Nano assets are downloading.';
          _totalBytes = _readInteger(event['totalBytes']);
          _downloadedBytes = 0;
          _downloadMessage = 'Download started.';
          break;

        case 'progress':
          _status = 'DOWNLOADING';
          _downloadedBytes = _readInteger(event['downloadedBytes']);
          _totalBytes = _readInteger(event['totalBytes']) ?? _totalBytes;
          _downloadMessage = 'Downloading Gemini Nano assets…';
          break;

        case 'completed':
          _status = 'AVAILABLE';
          _description = 'Gemini Nano is downloaded and ready to use.';
          _downloadedBytes =
              _readInteger(event['downloadedBytes']) ?? _totalBytes;
          _totalBytes = _readInteger(event['totalBytes']) ?? _totalBytes;
          _downloadMessage = 'Download completed successfully.';
          _errorDetails = null;
          break;

        case 'failed':
          _status = 'DOWNLOADABLE';
          _description =
              'This device supports Gemini Nano, but its assets are not ready.';
          _downloadMessage = null;
          _errorDetails =
              '${event['message'] ?? 'Gemini Nano download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
          break;
      }
    });
  }

  void _handleSummarizationDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _summarizationStatus = 'DOWNLOADING';
          _summarizationDescription =
              'The required summarization assets are downloading.';
          _summarizationTotalBytes = _readInteger(event['totalBytes']);
          _summarizationDownloadedBytes = 0;
          _summarizationDownloadMessage = 'Summarization download started.';
          break;

        case 'progress':
          _summarizationStatus = 'DOWNLOADING';
          _summarizationDownloadedBytes = _readInteger(
            event['downloadedBytes'],
          );
          _summarizationTotalBytes =
              _readInteger(event['totalBytes']) ?? _summarizationTotalBytes;
          _summarizationDownloadMessage = 'Downloading summarization assets…';
          break;

        case 'completed':
          _summarizationStatus = 'AVAILABLE';
          _summarizationDescription =
              'The dedicated Summarization API is ready to use.';
          _summarizationDownloadedBytes =
              _readInteger(event['downloadedBytes']) ??
              _summarizationTotalBytes;
          _summarizationTotalBytes =
              _readInteger(event['totalBytes']) ?? _summarizationTotalBytes;
          _summarizationDownloadMessage =
              'Summarization download completed successfully.';
          _summarizationError = null;
          break;

        case 'failed':
          _summarizationStatus = 'DOWNLOADABLE';
          _summarizationDescription =
              'This device supports summarization, but its assets are not ready.';
          _summarizationDownloadMessage = null;
          _summarizationError =
              '${event['message'] ?? 'Summarization asset download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
          break;
      }
    });
  }

  void _handlePromptEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _isRunningPrompt = true;
          _promptStatus = 'Generating…';
          _promptOutput = '';
          _candidates = <Map<String, dynamic>>[];
          _submittedPrompt = event['prompt']?.toString();
          _submittedSystemInstruction = event['systemInstruction']?.toString();
          final eventTemperature = event['temperature'];
          _submittedTemperature = eventTemperature is double
              ? eventTemperature
              : null;
          _submittedMaxOutputTokens = _readInteger(event['maxOutputTokens']);
          _submittedSeed = _readInteger(event['seed']);
          _submittedTopK = _readInteger(event['topK']);
          _submittedCandidateCount = _readInteger(event['candidateCount']);
          _promptError = null;
          _elapsedMilliseconds = null;
          _finishReason = null;
          _finishReasonCode = null;
          break;

        case 'chunk':
          _promptStatus = 'Generating…';
          _promptOutput += event['text']?.toString() ?? '';
          break;

        case 'completed':
          _isRunningPrompt = false;
          final candidateValues = event['candidates'];
          if (candidateValues is List) {
            _candidates = candidateValues
                .whereType<Map>()
                .map(
                  (candidate) => <String, dynamic>{
                    'text': candidate['text']?.toString() ?? '',
                    'finishReason': candidate['finishReason']?.toString(),
                    'finishReasonCode': _readInteger(
                      candidate['finishReasonCode'],
                    ),
                  },
                )
                .toList();
            if (_candidates.length == 1) {
              _promptOutput = _candidates.first['text']?.toString() ?? '';
            }
          }
          _finishReason = event['finishReason']?.toString();
          _finishReasonCode = _readInteger(event['finishReasonCode']);

          switch (_finishReason) {
            case 'STOP':
              _promptStatus = 'Completed';
              break;
            case 'MAX_TOKENS':
              _promptStatus = 'Stopped at token limit';
              break;
            case 'OTHER':
              _promptStatus = 'Stopped for another reason';
              break;
            default:
              _promptStatus = 'Finished; reason unknown';
          }

          _elapsedMilliseconds = _readInteger(event['elapsedMilliseconds']);

          if (_activeRunNumber != null &&
              _submittedPrompt != null &&
              _submittedTemperature != null &&
              _submittedMaxOutputTokens != null &&
              _submittedSeed != null &&
              _submittedTopK != null &&
              _submittedCandidateCount != null &&
              _elapsedMilliseconds != null &&
              _requestTokens != null &&
              _tokenLimit != null) {
            _completedRuns.add(
              _PromptRun(
                number: _activeRunNumber!,
                prompt: _submittedPrompt!,
                systemInstruction: _submittedSystemInstruction,
                temperature: _submittedTemperature!,
                maxOutputTokens: _submittedMaxOutputTokens!,
                seed: _submittedSeed!,
                topK: _submittedTopK!,
                candidateCount: _submittedCandidateCount!,
                modelReleaseStage: _modelReleaseStage,
                output: _promptOutput,
                candidates: _candidates
                    .map((candidate) => Map<String, dynamic>.from(candidate))
                    .toList(),
                elapsedMilliseconds: _elapsedMilliseconds!,
                requestTokens: _requestTokens!,
                tokenLimit: _tokenLimit!,
                finishReason: _finishReason,
                finishReasonCode: _finishReasonCode,
              ),
            );
          }
          _activeRunNumber = null;
          break;

        case 'failed':
          _isRunningPrompt = false;
          _activeRunNumber = null;
          _promptStatus = 'Error';
          _elapsedMilliseconds = _readInteger(event['elapsedMilliseconds']);
          _promptError =
              '${event['message'] ?? 'Gemini Nano inference failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });
  }

  void _handleDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _downloadMessage = null;
      _errorDetails = 'Download progress stream error: $error';
    });
  }

  void _handlePromptStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isRunningPrompt = false;
      _promptStatus = 'Error';
      _promptError = 'Prompt output stream error: $error';
    });
  }

  void _handleSummarizationDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _summarizationDownloadMessage = null;
      _summarizationError =
          'Summarization download progress stream error: $error';
    });
  }

  int? _readInteger(dynamic value) {
    return value is int ? value : null;
  }

  String _formatBytes(int bytes) {
    const bytesPerMiB = 1024 * 1024;
    return '${(bytes / bytesPerMiB).toStringAsFixed(1)} MiB';
  }

  String _formatElapsedTime(int milliseconds) {
    return '${(milliseconds / 1000).toStringAsFixed(2)} seconds';
  }

  Color _statusColor(ColorScheme colors) {
    switch (_status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
        return Colors.blue;
      case 'UNAVAILABLE':
      case 'ERROR':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  Color _summarizationStatusColor(ColorScheme colors) {
    switch (_summarizationStatus) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
        return Colors.blue;
      case 'UNAVAILABLE':
      case 'ERROR':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  Widget _buildRunComparisonCard(_PromptRun run) {
    final output = run.candidates.length > 1
        ? run.candidates
              .asMap()
              .entries
              .map(
                (entry) =>
                    'Candidate ${entry.key + 1}\n${entry.value['text'] ?? ''}',
              )
              .join('\n\n')
        : run.output;

    return SizedBox(
      width: 340,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Run ${run.number}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatElapsedTime(run.elapsedMilliseconds)} · '
                '${run.finishReason ?? 'UNKNOWN'}'
                '${run.finishReasonCode == null ? '' : ' (${run.finishReasonCode})'}',
              ),
              Text(
                '${run.requestTokens} request tokens · '
                '${run.modelReleaseStage.toLowerCase()}',
              ),
              Text(
                'Temp ${run.temperature.toStringAsFixed(1)} · '
                'Max ${run.maxOutputTokens} · Seed ${run.seed} · '
                'Top-K ${run.topK} · Candidates ${run.candidateCount}',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: run.rating,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Rating (optional)',
                ),
                items: const [
                  DropdownMenuItem(value: 'Accurate', child: Text('Accurate')),
                  DropdownMenuItem(
                    value: 'Partially accurate',
                    child: Text('Partially accurate'),
                  ),
                  DropdownMenuItem(
                    value: 'Incorrect',
                    child: Text('Incorrect'),
                  ),
                  DropdownMenuItem(
                    value: 'Missed instructions',
                    child: Text('Missed instructions'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    run.rating = value;
                  });
                },
              ),
              const Divider(height: 24),
              const Text(
                'Output',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(output),
              const Divider(height: 24),
              const Text(
                'System instruction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(run.systemInstruction ?? 'None'),
              const SizedBox(height: 12),
              const Text(
                'Prompt',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(run.prompt),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
    final summarizationStatusColor = _summarizationStatusColor(colors);
    final maxOutputTokens = int.tryParse(_maxOutputTokensController.text);
    final hasValidMaxOutputTokens =
        maxOutputTokens != null &&
        maxOutputTokens >= 1 &&
        maxOutputTokens <= 4096;
    final seed = int.tryParse(_seedController.text);
    final hasValidSeed = seed != null && seed >= 0 && seed <= 2147483647;
    final topK = int.tryParse(_topKController.text);
    final hasValidTopK = topK != null && topK >= 1 && topK <= 2147483647;
    final candidateCount = int.tryParse(_candidateCountController.text);
    final hasValidCandidateCount =
        candidateCount != null && candidateCount >= 1 && candidateCount <= 8;
    final hasValidSummarizationInput =
        _summarizationController.text.length > 400;

    double? progress;
    double? summarizationProgress;

    if (_downloadedBytes != null && _totalBytes != null && _totalBytes! > 0) {
      progress = (_downloadedBytes! / _totalBytes!).clamp(0.0, 1.0).toDouble();
    }

    if (_summarizationDownloadedBytes != null &&
        _summarizationTotalBytes != null &&
        _summarizationTotalBytes! > 0) {
      summarizationProgress =
          (_summarizationDownloadedBytes! / _summarizationTotalBytes!)
              .clamp(0.0, 1.0)
              .toDouble();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nano Lab')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gemini Nano status',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Check whether the ML Kit Prompt API is available through '
                'AICore.',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _modelReleaseStage,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Model release stage',
                ),
                items: const [
                  DropdownMenuItem(value: 'STABLE', child: Text('Stable')),
                  DropdownMenuItem(value: 'PREVIEW', child: Text('Preview')),
                ],
                onChanged:
                    _isChecking ||
                        _isStartingDownload ||
                        _isRunningPrompt ||
                        _isRunningSummarization ||
                        _isStartingSummarizationDownload
                    ? null
                    : (value) {
                        if (value != null && value != _modelReleaseStage) {
                          _setModelReleaseStage(value);
                        }
                      },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_description),
                      if (_deviceInformation != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        SelectableText(_deviceInformation!),
                      ],
                      if (_systemInstructionDescription != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'System instructions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_systemInstructionDescription!),
                      ],
                      if (_systemInstructionError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _systemInstructionError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                      if (_errorDetails != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _errorDetails!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_downloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 12),
                        Text(_downloadMessage!),
                        if (_downloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _totalBytes != null && _totalBytes! > 0
                                ? '${_formatBytes(_downloadedBytes!)} of '
                                      '${_formatBytes(_totalBytes!)}'
                                : _formatBytes(_downloadedBytes!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    _isChecking ||
                        _isStartingDownload ||
                        _isRunningSummarization ||
                        _isStartingSummarizationDownload
                    ? null
                    : _checkNanoStatus,
                icon: _isChecking
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.memory),
                label: Text(
                  _isChecking ? 'Checking…' : 'Check Gemini Nano status',
                ),
              ),
              if (_status == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingDownload ||
                          _isStartingSummarizationDownload ||
                          _isRunningSummarization
                      ? null
                      : _startDownload,
                  icon: _isStartingDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingDownload
                        ? 'Starting download…'
                        : 'Download Gemini Nano assets',
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Text(
                'Prompt test',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text('System instruction (optional):'),
              const SizedBox(height: 12),
              TextField(
                controller: _systemInstructionController,
                enabled: _systemInstructionAvailable && !_isRunningPrompt,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter an optional system instruction.',
                ),
              ),
              const SizedBox(height: 20),
              const Text('User prompt:'),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                enabled: !_isRunningPrompt,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a prompt for Gemini Nano.',
                ),
              ),
              const SizedBox(height: 20),
              Text('Temperature: ${_temperature.toStringAsFixed(1)}'),
              Slider(
                value: _temperature,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: _temperature.toStringAsFixed(1),
                onChanged: _isRunningPrompt
                    ? null
                    : (value) {
                        setState(() {
                          _temperature = value;
                        });
                      },
              ),
              const SizedBox(height: 8),
              const Text('Maximum output tokens:'),
              const SizedBox(height: 12),
              TextField(
                controller: _maxOutputTokensController,
                enabled: !_isRunningPrompt,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: 'Enter a whole number from 1 to 4096.',
                  errorText:
                      _maxOutputTokensController.text.isEmpty ||
                          hasValidMaxOutputTokens
                      ? null
                      : 'Enter a value from 1 to 4096.',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Seed:'),
              const SizedBox(height: 12),
              TextField(
                controller: _seedController,
                enabled: !_isRunningPrompt,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText:
                      'Use 0 for varying seeds or a fixed positive number.',
                  errorText: _seedController.text.isEmpty || hasValidSeed
                      ? null
                      : 'Enter a value from 0 to 2147483647.',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Top-K:'),
              const SizedBox(height: 12),
              TextField(
                controller: _topKController,
                enabled: !_isRunningPrompt,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: 'Default is 3. Use a positive whole number.',
                  errorText: _topKController.text.isEmpty || hasValidTopK
                      ? null
                      : 'Enter a value from 1 to 2147483647.',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Candidate count:'),
              const SizedBox(height: 12),
              TextField(
                controller: _candidateCountController,
                enabled: !_isRunningPrompt,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText:
                      'Request 1 to 8 unique responses. Multiple candidates are not streamed.',
                  errorText:
                      _candidateCountController.text.isEmpty ||
                          hasValidCandidateCount
                      ? null
                      : 'Enter a value from 1 to 8.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    _status == 'AVAILABLE' &&
                        !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        hasValidMaxOutputTokens &&
                        hasValidSeed &&
                        hasValidTopK &&
                        hasValidCandidateCount &&
                        _promptController.text.trim().isNotEmpty
                    ? () => _runPrompt()
                    : null,
                icon: _isRunningPrompt
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunningPrompt ? 'Generating…' : 'Run prompt'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed:
                    !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        _completedRuns.isNotEmpty
                    ? () => _runPrompt(repeatRun: _completedRuns.last)
                    : null,
                icon: const Icon(Icons.replay),
                label: const Text('Run exact request again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    !_isRunningPrompt &&
                        (_promptOutput.isNotEmpty ||
                            _candidates.isNotEmpty ||
                            _promptError != null ||
                            _elapsedMilliseconds != null)
                    ? _clearPromptOutput
                    : null,
                icon: const Icon(Icons.clear),
                label: const Text('Clear output'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Run ${_activeRunNumber ?? (_completedRuns.isEmpty ? '—' : _completedRuns.last.number)} · '
                        'Status: $_promptStatus',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_elapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Processing time: '
                          '${_formatElapsedTime(_elapsedMilliseconds!)}',
                        ),
                      ],
                      if (_finishReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Finish reason: $_finishReason'
                          '${_finishReasonCode == null ? '' : ' ($_finishReasonCode)'}',
                        ),
                      ],
                      if (_requestTokens != null && _tokenLimit != null) ...[
                        const SizedBox(height: 8),
                        Text('Request tokens: $_requestTokens'),
                        Text(
                          'Combined input/output limit: $_tokenLimit tokens',
                        ),
                      ],
                      if (_submittedTemperature != null &&
                          _submittedMaxOutputTokens != null &&
                          _submittedSeed != null &&
                          _submittedTopK != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Temperature: '
                          '${_submittedTemperature!.toStringAsFixed(1)}',
                        ),
                        Text(
                          'Maximum output tokens: '
                          '$_submittedMaxOutputTokens',
                        ),
                        Text('Seed: $_submittedSeed'),
                        Text('Top-K: $_submittedTopK'),
                        if (_submittedCandidateCount != null)
                          Text('Candidate count: $_submittedCandidateCount'),
                      ],
                      if (_submittedPrompt != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact system instruction sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedSystemInstruction ?? 'None'),
                        const SizedBox(height: 16),
                        const Text(
                          'Exact prompt sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedPrompt!),
                      ],
                      const SizedBox(height: 16),
                      if (_candidates.length > 1)
                        for (
                          var index = 0;
                          index < _candidates.length;
                          index++
                        ) ...[
                          Text(
                            'Candidate ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _candidates[index]['text']?.toString() ?? '',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Finish reason: '
                            '${_candidates[index]['finishReason'] ?? 'UNKNOWN'}'
                            '${_candidates[index]['finishReasonCode'] == null ? '' : ' (${_candidates[index]['finishReasonCode']})'}',
                          ),
                          if (index < _candidates.length - 1)
                            const Divider(height: 32),
                        ]
                      else
                        SelectableText(
                          _promptOutput.isEmpty
                              ? (_submittedCandidateCount != null &&
                                        _submittedCandidateCount! > 1
                                    ? 'Candidate responses will appear when generation completes.'
                                    : 'Streaming output will appear here.')
                              : _promptOutput,
                        ),
                      if (_promptError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _promptError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_completedRuns.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Session comparison',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swipe horizontally to compare completed runs. Results are '
                  'kept only until the app is closed.',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        var index = 0;
                        index < _completedRuns.length;
                        index++
                      ) ...[
                        _buildRunComparisonCard(_completedRuns[index]),
                        if (index < _completedRuns.length - 1)
                          const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Text(
                'Dedicated summarization test',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uses the ML Kit Summarization API with fixed English article '
                'input and one-bullet output. Article input must contain more '
                'than 400 characters.',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: summarizationStatusColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: summarizationStatusColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _summarizationStatus,
                            style: TextStyle(
                              color: summarizationStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_summarizationDescription),
                      if (_summarizationError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _summarizationError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _isCheckingSummarization ||
                        _isStartingSummarizationDownload ||
                        _isRunningSummarization ||
                        _isRunningPrompt ||
                        _isStartingDownload
                    ? null
                    : _checkSummarizationStatus,
                icon: _isCheckingSummarization
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.summarize),
                label: Text(
                  _isCheckingSummarization
                      ? 'Checking…'
                      : 'Check summarization status',
                ),
              ),
              if (_summarizationStatus == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingSummarizationDownload ||
                          _isStartingDownload ||
                          _isRunningPrompt ||
                          _isRunningSummarization
                      ? null
                      : _startSummarizationDownload,
                  icon: _isStartingSummarizationDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingSummarizationDownload
                        ? 'Starting download…'
                        : 'Download summarization assets',
                  ),
                ),
              ],
              if (_summarizationDownloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(value: summarizationProgress),
                        const SizedBox(height: 12),
                        Text(_summarizationDownloadMessage!),
                        if (_summarizationDownloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _summarizationTotalBytes != null &&
                                    _summarizationTotalBytes! > 0
                                ? '${_formatBytes(_summarizationDownloadedBytes!)} of '
                                      '${_formatBytes(_summarizationTotalBytes!)}'
                                : _formatBytes(_summarizationDownloadedBytes!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Article text:'),
              const SizedBox(height: 12),
              TextField(
                controller: _summarizationController,
                enabled: !_isRunningSummarization,
                minLines: 10,
                maxLines: 18,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText:
                      '${_summarizationController.text.length} characters',
                  errorText:
                      _summarizationController.text.isEmpty ||
                          hasValidSummarizationInput
                      ? null
                      : 'Enter more than 400 characters.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _summarizationStatus == 'AVAILABLE' &&
                        !_isRunningSummarization &&
                        !_isRunningPrompt &&
                        hasValidSummarizationInput
                    ? _runSummarization
                    : null,
                icon: _isRunningSummarization
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunningSummarization ? 'Summarizing…' : 'Summarize',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Status: ${_isRunningSummarization
                            ? 'Summarizing…'
                            : _summarizationError != null
                            ? 'Error'
                            : _summarizationOutput.isNotEmpty
                            ? 'Completed'
                            : 'Not run'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_summarizationElapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Processing time: '
                          '${_formatElapsedTime(_summarizationElapsedMilliseconds!)}',
                        ),
                      ],
                      if (_submittedSummarizationInput != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact input sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedSummarizationInput!),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Output:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _summarizationOutput.isEmpty
                            ? 'The summary will appear here.'
                            : _summarizationOutput,
                      ),
                      if (_summarizationError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _summarizationError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
