import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/nano_native_service.dart';
import 'nano_lab_section.dart';

class TechnicalLabScreen extends StatefulWidget {
  const TechnicalLabScreen({
    super.key,
    this.initialSection,
    this.everydayMode = false,
    this.nativeService = const NanoNativeService(),
  });

  final NanoLabSection? initialSection;
  final bool everydayMode;
  final NanoNativeService nativeService;

  @override
  State<TechnicalLabScreen> createState() => _TechnicalLabScreenState();
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

class _TechnicalLabScreenState extends State<TechnicalLabScreen> {
  final GlobalKey _statusSectionKey = GlobalKey();
  final GlobalKey _promptSectionKey = GlobalKey();
  final GlobalKey _summarizationSectionKey = GlobalKey();
  final GlobalKey _rewritingSectionKey = GlobalKey();
  final GlobalKey _proofreadingSectionKey = GlobalKey();
  final GlobalKey _imageDescriptionSectionKey = GlobalKey();
  final GlobalKey _speechRecognitionSectionKey = GlobalKey();

  late final NanoNativeService _nativeService;

  static const _syntheticImageDescriptionTestImageId =
      'synthetic_house_scene_v1';
  static const _realPhotoImageDescriptionTestImageId = 'real_tabletop_photo_v1';

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

  static const _defaultRewritingText =
      'hey sam, the fictional Alder Cove tool library opens Tuesday at 4:00 '
      'PM, and the town council votes on permanent funding October 12, 2026. '
      'please send me the inventory list by Friday so I can check it.';

  static const _defaultProofreadingText =
      'the fictional Northbridge office recieve 17 packages on Monday, but '
      'three was labeld incorrect and needs to be checked by Friday.';

  static const _speechRecognitionTestPhrase =
      'On Monday, August seventeenth, twenty twenty-six, the fictional '
      'Northbridge office received seventeen packages. Three were labeled '
      'incorrectly and must be checked by Friday at four fifteen P.M.';

  late final TextEditingController _promptController;
  late final TextEditingController _systemInstructionController;
  late final TextEditingController _maxOutputTokensController;
  late final TextEditingController _seedController;
  late final TextEditingController _topKController;
  late final TextEditingController _candidateCountController;
  late final TextEditingController _summarizationController;
  late final TextEditingController _rewritingController;
  late final TextEditingController _proofreadingController;

  late final StreamSubscription<dynamic> _downloadSubscription;
  late final StreamSubscription<dynamic> _promptSubscription;
  late final StreamSubscription<dynamic> _summarizationDownloadSubscription;
  late final StreamSubscription<dynamic> _rewritingDownloadSubscription;
  late final StreamSubscription<dynamic> _proofreadingDownloadSubscription;
  late final StreamSubscription<dynamic> _imageDescriptionDownloadSubscription;
  late final StreamSubscription<dynamic> _speechRecognitionDownloadSubscription;
  late final StreamSubscription<dynamic> _speechRecognitionSubscription;

  bool _isChecking = false;
  bool _isStartingDownload = false;
  bool _isRunningPrompt = false;
  bool _isRunningTopKComparison = false;
  int? _topKComparisonStep;
  bool _isCheckingSummarization = false;
  bool _isStartingSummarizationDownload = false;
  bool _isRunningSummarization = false;
  bool _isCheckingRewriting = false;
  bool _isStartingRewritingDownload = false;
  bool _isRunningRewriting = false;
  bool _isCheckingProofreading = false;
  bool _isStartingProofreadingDownload = false;
  bool _isRunningProofreading = false;
  bool _isCheckingImageDescription = false;
  bool _isStartingImageDescriptionDownload = false;
  bool _isRunningImageDescription = false;
  bool _isLoadingImageDescriptionTestImage = false;
  bool _isCheckingSpeechRecognition = false;
  bool _isStartingSpeechRecognitionDownload = false;
  bool _isStartingSpeechRecognition = false;
  bool _isStoppingSpeechRecognition = false;
  bool _isRunningSpeechRecognition = false;
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
  Completer<bool>? _promptRunCompletion;

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

  String _rewritingStatus = 'NOT CHECKED';
  String _rewritingDescription =
      'Check whether the dedicated ML Kit Rewriting API is available.';
  String? _rewritingError;
  String? _rewritingDownloadMessage;
  String? _submittedRewritingInput;
  String _rewritingOutput = '';
  int? _rewritingDownloadedBytes;
  int? _rewritingTotalBytes;
  int? _rewritingElapsedMilliseconds;
  int? _rewritingSuggestionCount;

  String _proofreadingStatus = 'NOT CHECKED';
  String _proofreadingDescription =
      'Check whether the dedicated ML Kit Proofreading API is available.';
  String? _proofreadingError;
  String? _proofreadingDownloadMessage;
  String? _submittedProofreadingInput;
  String _proofreadingOutput = '';
  int? _proofreadingDownloadedBytes;
  int? _proofreadingTotalBytes;
  int? _proofreadingElapsedMilliseconds;
  int? _proofreadingSuggestionCount;

  String _imageDescriptionStatus = 'NOT CHECKED';
  String _imageDescriptionDescription =
      'Check whether the dedicated ML Kit Image Description API is available.';
  String? _imageDescriptionError;
  String? _imageDescriptionDownloadMessage;
  String _selectedImageDescriptionTestImageId =
      _syntheticImageDescriptionTestImageId;
  Uint8List? _imageDescriptionTestImageBytes;
  String? _imageDescriptionTestImageId;
  int? _imageDescriptionTestImageWidth;
  int? _imageDescriptionTestImageHeight;
  String _imageDescriptionOutput = '';
  int? _imageDescriptionDownloadedBytes;
  int? _imageDescriptionTotalBytes;
  int? _imageDescriptionElapsedMilliseconds;

  String _speechRecognitionStatus = 'NOT CHECKED';
  String _speechRecognitionDescription =
      'Check whether Advanced en-US speech recognition is available.';
  String _speechRecognitionSessionStatus = 'Not run';
  String? _speechRecognitionError;
  String? _speechRecognitionDownloadMessage;
  String _speechRecognitionPartialText = '';
  String _speechRecognitionFinalText = '';
  int? _speechRecognitionDownloadedBytes;
  int? _speechRecognitionTotalBytes;
  int? _speechRecognitionElapsedMilliseconds;

  @override
  void initState() {
    super.initState();

    _nativeService = widget.nativeService;

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
    _rewritingController = TextEditingController(text: _defaultRewritingText);
    _proofreadingController = TextEditingController(
      text: _defaultProofreadingText,
    );

    _downloadSubscription = _nativeService.promptDownloadEvents.listen(
      _handleDownloadEvent,
      onError: _handleDownloadStreamError,
    );

    _promptSubscription = _nativeService.promptEvents.listen(
      _handlePromptEvent,
      onError: _handlePromptStreamError,
    );

    _summarizationDownloadSubscription = _nativeService
        .summarizationDownloadEvents
        .listen(
          _handleSummarizationDownloadEvent,
          onError: _handleSummarizationDownloadStreamError,
        );

    _rewritingDownloadSubscription = _nativeService.rewritingDownloadEvents
        .listen(
          _handleRewritingDownloadEvent,
          onError: _handleRewritingDownloadStreamError,
        );

    _proofreadingDownloadSubscription = _nativeService
        .proofreadingDownloadEvents
        .listen(
          _handleProofreadingDownloadEvent,
          onError: _handleProofreadingDownloadStreamError,
        );

    _imageDescriptionDownloadSubscription = _nativeService
        .imageDescriptionDownloadEvents
        .listen(
          _handleImageDescriptionDownloadEvent,
          onError: _handleImageDescriptionDownloadStreamError,
        );

    _speechRecognitionDownloadSubscription = _nativeService
        .speechRecognitionDownloadEvents
        .listen(
          _handleSpeechRecognitionDownloadEvent,
          onError: _handleSpeechRecognitionDownloadStreamError,
        );

    _speechRecognitionSubscription = _nativeService.speechRecognitionEvents
        .listen(
          _handleSpeechRecognitionEvent,
          onError: _handleSpeechRecognitionStreamError,
        );

    _loadImageDescriptionTestImage();

    if (widget.everydayMode && widget.initialSection == NanoLabSection.prompt) {
      _systemInstructionController.clear();
    }

    final initialSection = widget.initialSection;
    if (!widget.everydayMode && initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _jumpToSection(initialSection);
        }
      });
    }
  }

  @override
  void dispose() {
    _completePromptRun(false);
    _downloadSubscription.cancel();
    _promptSubscription.cancel();
    _summarizationDownloadSubscription.cancel();
    _rewritingDownloadSubscription.cancel();
    _proofreadingDownloadSubscription.cancel();
    _imageDescriptionDownloadSubscription.cancel();
    _speechRecognitionDownloadSubscription.cancel();
    _speechRecognitionSubscription.cancel();
    _promptController.dispose();
    _systemInstructionController.dispose();
    _maxOutputTokensController.dispose();
    _seedController.dispose();
    _topKController.dispose();
    _candidateCountController.dispose();
    _summarizationController.dispose();
    _rewritingController.dispose();
    _proofreadingController.dispose();
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
      final result = await _nativeService.getPromptStatus();

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
      final result = await _nativeService.setModelReleaseStage(releaseStage);

      if (!mounted) {
        return;
      }

      if (result?['modelReleaseStage']?.toString() != releaseStage) {
        setState(() {
          _status = 'ERROR';
          _description = 'Kotlin did not select the requested model stage.';
        });
        return;
      }

      await _checkNanoStatus();
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
      final result = await _nativeService.getSystemInstructionStatus();

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
      await _nativeService.startPromptDownload();

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
      final result = await _nativeService.getSummarizationStatus();

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
      await _nativeService.startSummarizationDownload();

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
      final result = await _nativeService.runSummarization(input);
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

  Future<void> _checkRewritingStatus() async {
    setState(() {
      _isCheckingRewriting = true;
      _rewritingStatus = 'CHECKING';
      _rewritingDescription =
          'Checking the dedicated Rewriting API configuration…';
      _rewritingError = null;
    });

    try {
      final result = await _nativeService.getRewritingStatus();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _rewritingStatus = 'ERROR';
          _rewritingDescription =
              'Kotlin returned no rewriting status information.';
        });
        return;
      }

      setState(() {
        _rewritingStatus = result['status']?.toString() ?? 'UNKNOWN';
        _rewritingDescription =
            result['description']?.toString() ??
            'No rewriting status description was returned.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingStatus = 'ERROR';
        _rewritingDescription =
            error.message ?? 'Rewriting status detection failed.';
        _rewritingError = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingStatus = 'ERROR';
        _rewritingDescription = 'Unexpected rewriting status-check failure.';
        _rewritingError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRewriting = false;
        });
      }
    }
  }

  Future<void> _startRewritingDownload() async {
    setState(() {
      _isStartingRewritingDownload = true;
      _rewritingDownloadMessage = 'Requesting the rewriting asset download…';
      _rewritingDownloadedBytes = null;
      _rewritingTotalBytes = null;
      _rewritingError = null;
    });

    try {
      await _nativeService.startRewritingDownload();

      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingStatus = 'DOWNLOADING';
        _rewritingDescription =
            'The required rewriting assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingDownloadMessage = null;
        _rewritingError =
            '${error.message ?? 'The rewriting download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingDownloadMessage = null;
        _rewritingError = 'Unexpected rewriting download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRewritingDownload = false;
        });
      }
    }
  }

  Future<void> _runRewriting() async {
    final input = _rewritingController.text;
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isRunningRewriting = true;
      _submittedRewritingInput = input;
      _rewritingOutput = '';
      _rewritingElapsedMilliseconds = null;
      _rewritingSuggestionCount = null;
      _rewritingError = null;
    });

    try {
      final result = await _nativeService.runRewriting(input);
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _rewritingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _rewritingError = 'Kotlin returned no rewriting result.';
        });
        return;
      }

      final nativeInput = result['input']?.toString();
      if (nativeInput != input) {
        setState(() {
          _rewritingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _rewritingError =
              'The native rewriting input did not match the displayed input.';
        });
        return;
      }

      setState(() {
        _rewritingOutput = result['output']?.toString() ?? '';
        _rewritingSuggestionCount = _readInteger(result['suggestionCount']);
        _rewritingElapsedMilliseconds =
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
        _rewritingElapsedMilliseconds =
            nativeElapsedMilliseconds ?? stopwatch.elapsedMilliseconds;
        _rewritingError =
            '${error.message ?? 'Gemini Nano rewriting failed.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _rewritingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
        _rewritingError = 'Unexpected rewriting error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningRewriting = false;
        });
      }
    }
  }

  Future<void> _checkProofreadingStatus() async {
    setState(() {
      _isCheckingProofreading = true;
      _proofreadingStatus = 'CHECKING';
      _proofreadingDescription =
          'Checking the dedicated Proofreading API configuration…';
      _proofreadingError = null;
    });

    try {
      final result = await _nativeService.getProofreadingStatus();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _proofreadingStatus = 'ERROR';
          _proofreadingDescription =
              'Kotlin returned no proofreading status information.';
        });
        return;
      }

      setState(() {
        _proofreadingStatus = result['status']?.toString() ?? 'UNKNOWN';
        _proofreadingDescription =
            result['description']?.toString() ??
            'No proofreading status description was returned.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingStatus = 'ERROR';
        _proofreadingDescription =
            error.message ?? 'Proofreading status detection failed.';
        _proofreadingError = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingStatus = 'ERROR';
        _proofreadingDescription =
            'Unexpected proofreading status-check failure.';
        _proofreadingError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingProofreading = false;
        });
      }
    }
  }

  Future<void> _startProofreadingDownload() async {
    setState(() {
      _isStartingProofreadingDownload = true;
      _proofreadingDownloadMessage =
          'Requesting the proofreading asset download…';
      _proofreadingDownloadedBytes = null;
      _proofreadingTotalBytes = null;
      _proofreadingError = null;
    });

    try {
      await _nativeService.startProofreadingDownload();

      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingStatus = 'DOWNLOADING';
        _proofreadingDescription =
            'The required proofreading assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingDownloadMessage = null;
        _proofreadingError =
            '${error.message ?? 'The proofreading download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingDownloadMessage = null;
        _proofreadingError = 'Unexpected proofreading download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingProofreadingDownload = false;
        });
      }
    }
  }

  Future<void> _runProofreading() async {
    final input = _proofreadingController.text;
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isRunningProofreading = true;
      _submittedProofreadingInput = input;
      _proofreadingOutput = '';
      _proofreadingElapsedMilliseconds = null;
      _proofreadingSuggestionCount = null;
      _proofreadingError = null;
    });

    try {
      final result = await _nativeService.runProofreading(input);
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _proofreadingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _proofreadingError = 'Kotlin returned no proofreading result.';
        });
        return;
      }

      final nativeInput = result['input']?.toString();
      if (nativeInput != input) {
        setState(() {
          _proofreadingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _proofreadingError =
              'The native proofreading input did not match the displayed input.';
        });
        return;
      }

      setState(() {
        _proofreadingOutput = result['output']?.toString() ?? '';
        _proofreadingSuggestionCount = _readInteger(result['suggestionCount']);
        _proofreadingElapsedMilliseconds =
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
        _proofreadingElapsedMilliseconds =
            nativeElapsedMilliseconds ?? stopwatch.elapsedMilliseconds;
        _proofreadingError =
            '${error.message ?? 'Gemini Nano proofreading failed.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _proofreadingElapsedMilliseconds = stopwatch.elapsedMilliseconds;
        _proofreadingError = 'Unexpected proofreading error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningProofreading = false;
        });
      }
    }
  }

  Future<void> _loadImageDescriptionTestImage({String? imageId}) async {
    final requestedImageId = imageId ?? _selectedImageDescriptionTestImageId;

    setState(() {
      _isLoadingImageDescriptionTestImage = true;
      _imageDescriptionTestImageBytes = null;
      _imageDescriptionTestImageId = null;
      _imageDescriptionTestImageWidth = null;
      _imageDescriptionTestImageHeight = null;
      _imageDescriptionError = null;
    });

    try {
      final result = await _nativeService.getImageDescriptionTestImage(
        requestedImageId,
      );

      if (!mounted) {
        return;
      }

      final imageBytes = result?['imageBytes'];
      if (result == null || imageBytes is! Uint8List) {
        setState(() {
          _imageDescriptionError =
              'Kotlin returned no valid image-description test image.';
        });
        return;
      }

      if (result['imageId']?.toString() != requestedImageId) {
        setState(() {
          _imageDescriptionError =
              'Kotlin returned a different image-description test image.';
        });
        return;
      }

      setState(() {
        _imageDescriptionTestImageBytes = imageBytes;
        _imageDescriptionTestImageId = result['imageId']?.toString();
        _imageDescriptionTestImageWidth = _readInteger(result['width']);
        _imageDescriptionTestImageHeight = _readInteger(result['height']);
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionError =
            '${error.message ?? 'The fixed image-description test scene could not be loaded.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionError =
            'Unexpected image-description test-image error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImageDescriptionTestImage = false;
        });
      }
    }
  }

  Future<void> _selectImageDescriptionTestImage(String imageId) async {
    setState(() {
      _selectedImageDescriptionTestImageId = imageId;
      _imageDescriptionOutput = '';
      _imageDescriptionElapsedMilliseconds = null;
      _imageDescriptionError = null;
    });

    await _loadImageDescriptionTestImage(imageId: imageId);
  }

  Future<void> _checkImageDescriptionStatus() async {
    setState(() {
      _isCheckingImageDescription = true;
      _imageDescriptionStatus = 'CHECKING';
      _imageDescriptionDescription =
          'Checking the dedicated Image Description API configuration…';
      _imageDescriptionError = null;
    });

    try {
      final result = await _nativeService.getImageDescriptionStatus();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _imageDescriptionStatus = 'ERROR';
          _imageDescriptionDescription =
              'Kotlin returned no image-description status information.';
        });
        return;
      }

      setState(() {
        _imageDescriptionStatus = result['status']?.toString() ?? 'UNKNOWN';
        _imageDescriptionDescription =
            result['description']?.toString() ??
            'No image-description status description was returned.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionStatus = 'ERROR';
        _imageDescriptionDescription =
            error.message ?? 'Image-description status detection failed.';
        _imageDescriptionError = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionStatus = 'ERROR';
        _imageDescriptionDescription =
            'Unexpected image-description status-check failure.';
        _imageDescriptionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingImageDescription = false;
        });
      }
    }
  }

  Future<void> _startImageDescriptionDownload() async {
    setState(() {
      _isStartingImageDescriptionDownload = true;
      _imageDescriptionDownloadMessage =
          'Requesting the image-description asset download…';
      _imageDescriptionDownloadedBytes = null;
      _imageDescriptionTotalBytes = null;
      _imageDescriptionError = null;
    });

    try {
      await _nativeService.startImageDescriptionDownload();

      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionStatus = 'DOWNLOADING';
        _imageDescriptionDescription =
            'The required image-description assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionDownloadMessage = null;
        _imageDescriptionError =
            '${error.message ?? 'The image-description download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionDownloadMessage = null;
        _imageDescriptionError =
            'Unexpected image-description download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingImageDescriptionDownload = false;
        });
      }
    }
  }

  Future<void> _runImageDescription() async {
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isRunningImageDescription = true;
      _imageDescriptionOutput = '';
      _imageDescriptionElapsedMilliseconds = null;
      _imageDescriptionError = null;
    });

    try {
      final result = await _nativeService.runImageDescription(
        _selectedImageDescriptionTestImageId,
      );
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _imageDescriptionElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _imageDescriptionError =
              'Kotlin returned no image-description result.';
        });
        return;
      }

      final nativeImageId = result['imageId']?.toString();
      final nativeWidth = _readInteger(result['width']);
      final nativeHeight = _readInteger(result['height']);
      if (nativeImageId != _imageDescriptionTestImageId ||
          nativeWidth != _imageDescriptionTestImageWidth ||
          nativeHeight != _imageDescriptionTestImageHeight) {
        setState(() {
          _imageDescriptionElapsedMilliseconds = stopwatch.elapsedMilliseconds;
          _imageDescriptionError =
              'The native inference image did not match the displayed test image.';
        });
        return;
      }

      setState(() {
        _imageDescriptionOutput = result['output']?.toString() ?? '';
        _imageDescriptionElapsedMilliseconds =
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
        _imageDescriptionElapsedMilliseconds =
            nativeElapsedMilliseconds ?? stopwatch.elapsedMilliseconds;
        _imageDescriptionError =
            '${error.message ?? 'Gemini Nano image description failed.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      stopwatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _imageDescriptionElapsedMilliseconds = stopwatch.elapsedMilliseconds;
        _imageDescriptionError = 'Unexpected image-description error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningImageDescription = false;
        });
      }
    }
  }

  Future<void> _checkSpeechRecognitionStatus() async {
    setState(() {
      _isCheckingSpeechRecognition = true;
      _speechRecognitionStatus = 'CHECKING';
      _speechRecognitionDescription =
          'Checking the Advanced en-US speech-recognition configuration…';
      _speechRecognitionError = null;
    });

    try {
      final result = await _nativeService.getSpeechRecognitionStatus();

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _speechRecognitionStatus = 'ERROR';
          _speechRecognitionDescription =
              'Kotlin returned no speech-recognition status information.';
        });
        return;
      }

      setState(() {
        _speechRecognitionStatus = result['status']?.toString() ?? 'UNKNOWN';
        _speechRecognitionDescription =
            result['description']?.toString() ??
            'No speech-recognition status description was returned.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionStatus = 'ERROR';
        _speechRecognitionDescription =
            error.message ?? 'Speech-recognition status detection failed.';
        _speechRecognitionError = 'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionStatus = 'ERROR';
        _speechRecognitionDescription =
            'Unexpected speech-recognition status-check failure.';
        _speechRecognitionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSpeechRecognition = false;
        });
      }
    }
  }

  Future<void> _startSpeechRecognitionDownload() async {
    setState(() {
      _isStartingSpeechRecognitionDownload = true;
      _speechRecognitionDownloadMessage =
          'Requesting the speech-recognition asset download…';
      _speechRecognitionDownloadedBytes = null;
      _speechRecognitionTotalBytes = null;
      _speechRecognitionError = null;
    });

    try {
      await _nativeService.startSpeechRecognitionDownload();

      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionStatus = 'DOWNLOADING';
        _speechRecognitionDescription =
            'The required speech-recognition assets are downloading.';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionDownloadMessage = null;
        _speechRecognitionError =
            '${error.message ?? 'The speech-recognition download could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionDownloadMessage = null;
        _speechRecognitionError =
            'Unexpected speech-recognition download error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSpeechRecognitionDownload = false;
        });
      }
    }
  }

  Future<void> _startSpeechRecognition() async {
    setState(() {
      _isStartingSpeechRecognition = true;
      _speechRecognitionSessionStatus = 'Requesting microphone permission…';
      _speechRecognitionPartialText = '';
      _speechRecognitionFinalText = '';
      _speechRecognitionElapsedMilliseconds = null;
      _speechRecognitionError = null;
    });

    try {
      final permissionResult = await _nativeService
          .requestSpeechRecognitionPermission();

      if (!mounted) {
        return;
      }

      if (permissionResult?['granted'] != true) {
        setState(() {
          _speechRecognitionSessionStatus = 'Permission denied';
          _speechRecognitionError =
              'Microphone permission is required for the live speech test. '
              'You can allow it in Android app settings and try again.';
        });
        return;
      }

      setState(() {
        _speechRecognitionSessionStatus = 'Starting microphone…';
      });

      await _nativeService.startSpeechRecognition();
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionSessionStatus = 'Error';
        _isRunningSpeechRecognition = false;
        _speechRecognitionError =
            '${error.message ?? 'Speech recognition could not be started.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionSessionStatus = 'Error';
        _isRunningSpeechRecognition = false;
        _speechRecognitionError =
            'Unexpected speech-recognition start error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSpeechRecognition = false;
        });
      }
    }
  }

  Future<void> _stopSpeechRecognition() async {
    setState(() {
      _isStoppingSpeechRecognition = true;
      _speechRecognitionSessionStatus = 'Stopping…';
      _speechRecognitionError = null;
    });

    try {
      await _nativeService.stopSpeechRecognition();
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionSessionStatus = 'Stop failed';
        _speechRecognitionError =
            '${error.message ?? 'Speech recognition could not be stopped.'}\n'
            'Platform error: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechRecognitionSessionStatus = 'Stop failed';
        _speechRecognitionError =
            'Unexpected speech-recognition stop error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStoppingSpeechRecognition = false;
        });
      }
    }
  }

  Future<bool> _runPrompt({
    _PromptRun? repeatRun,
    double? temperatureOverride,
    int? seedOverride,
    int? topKOverride,
    int? candidateCountOverride,
    bool waitForCompletion = false,
  }) async {
    final prompt = repeatRun?.prompt ?? _promptController.text;
    final systemInstruction = repeatRun == null
        ? _systemInstructionController.text
        : (repeatRun.systemInstruction ?? '');
    final temperature =
        repeatRun?.temperature ?? temperatureOverride ?? _temperature;
    final maxOutputTokens =
        repeatRun?.maxOutputTokens ??
        int.tryParse(_maxOutputTokensController.text);
    final seed =
        repeatRun?.seed ?? seedOverride ?? int.tryParse(_seedController.text);
    final topK =
        repeatRun?.topK ?? topKOverride ?? int.tryParse(_topKController.text);
    final candidateCount =
        repeatRun?.candidateCount ??
        candidateCountOverride ??
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
      return false;
    }

    if (maxOutputTokens == null ||
        maxOutputTokens < 1 ||
        maxOutputTokens > 4096) {
      setState(() {
        _promptStatus = 'Error';
        _promptError =
            'Maximum output tokens must be a whole number from 1 to 4096.';
      });
      return false;
    }

    if (seed == null || seed < 0 || seed > 2147483647) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Seed must be a whole number from 0 to 2147483647.';
      });
      return false;
    }

    if (topK == null || topK < 1 || topK > 2147483647) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Top-K must be a whole number from 1 to 2147483647.';
      });
      return false;
    }

    if (candidateCount == null || candidateCount < 1 || candidateCount > 8) {
      setState(() {
        _promptStatus = 'Error';
        _promptError = 'Candidate count must be a whole number from 1 to 8.';
      });
      return false;
    }

    final promptRunCompletion = waitForCompletion ? Completer<bool>() : null;
    _promptRunCompletion = promptRunCompletion;

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
      final tokenResult = await _nativeService.getTokenInfo(<String, dynamic>{
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
        return false;
      }

      if (tokenResult == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned no token information.';
        });
        _completePromptRun(false);
        return false;
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
        _completePromptRun(false);
        return false;
      }

      final requestTokens = _readInteger(tokenResult['requestTokens']);
      final tokenLimit = _readInteger(tokenResult['tokenLimit']);

      if (requestTokens == null || tokenLimit == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned incomplete token information.';
        });
        _completePromptRun(false);
        return false;
      }

      setState(() {
        _requestTokens = requestTokens;
        _tokenLimit = tokenLimit;
        _activeRunNumber = _nextRunNumber;
        _nextRunNumber++;
      });

      final result = await _nativeService.runPrompt(<String, dynamic>{
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
        return false;
      }

      if (result == null) {
        setState(() {
          _isRunningPrompt = false;
          _promptStatus = 'Error';
          _promptError = 'Kotlin returned no inference-start information.';
        });
        _completePromptRun(false);
        return false;
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
        _completePromptRun(false);
        return false;
      }

      if (promptRunCompletion != null) {
        return promptRunCompletion.future;
      }
      return true;
    } on PlatformException catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isRunningPrompt = false;
        _promptStatus = 'Error';
        _promptError =
            '${error.message ?? 'Token counting or Gemini Nano inference could not be started.'}\n'
            'Platform error: ${error.code}';
      });
      _completePromptRun(false);
      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isRunningPrompt = false;
        _promptStatus = 'Error';
        _promptError = 'Unexpected inference error: $error';
      });
      _completePromptRun(false);
      return false;
    }
  }

  void _completePromptRun(bool succeeded) {
    final completion = _promptRunCompletion;
    _promptRunCompletion = null;

    if (completion != null && !completion.isCompleted) {
      completion.complete(succeeded);
    }
  }

  Future<void> _runTopKComparison() async {
    const topKValues = <int>[1, 3, 10];
    var allRunsSucceeded = true;

    setState(() {
      _isRunningTopKComparison = true;
      _isRunningPrompt = true;
      _topKComparisonStep = 1;
      _promptError = null;
    });

    for (var index = 0; index < topKValues.length; index++) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topKComparisonStep = index + 1;
      });

      final succeeded = await _runPrompt(
        temperatureOverride: 0.7,
        seedOverride: 123,
        topKOverride: topKValues[index],
        candidateCountOverride: 1,
        waitForCompletion: true,
      );

      if (!succeeded) {
        allRunsSucceeded = false;
        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRunningTopKComparison = false;
      _isRunningPrompt = false;
      _topKComparisonStep = null;
      if (allRunsSucceeded) {
        _promptStatus = 'Top-K comparison completed';
      }
    });
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

  void _handleRewritingDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _rewritingStatus = 'DOWNLOADING';
          _rewritingDescription =
              'The required rewriting assets are downloading.';
          _rewritingTotalBytes = _readInteger(event['totalBytes']);
          _rewritingDownloadedBytes = 0;
          _rewritingDownloadMessage = 'Rewriting download started.';
          break;

        case 'progress':
          _rewritingStatus = 'DOWNLOADING';
          _rewritingDownloadedBytes = _readInteger(event['downloadedBytes']);
          _rewritingTotalBytes =
              _readInteger(event['totalBytes']) ?? _rewritingTotalBytes;
          _rewritingDownloadMessage = 'Downloading rewriting assets…';
          break;

        case 'completed':
          _rewritingStatus = 'AVAILABLE';
          _rewritingDescription =
              'The dedicated Rewriting API is ready to use.';
          _rewritingDownloadedBytes =
              _readInteger(event['downloadedBytes']) ?? _rewritingTotalBytes;
          _rewritingTotalBytes =
              _readInteger(event['totalBytes']) ?? _rewritingTotalBytes;
          _rewritingDownloadMessage =
              'Rewriting download completed successfully.';
          _rewritingError = null;
          break;

        case 'failed':
          _rewritingStatus = 'DOWNLOADABLE';
          _rewritingDescription =
              'This device supports rewriting, but its assets are not ready.';
          _rewritingDownloadMessage = null;
          _rewritingError =
              '${event['message'] ?? 'Rewriting asset download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
          break;
      }
    });
  }

  void _handleProofreadingDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _proofreadingStatus = 'DOWNLOADING';
          _proofreadingDescription =
              'The required proofreading assets are downloading.';
          _proofreadingTotalBytes = _readInteger(event['totalBytes']);
          _proofreadingDownloadedBytes = 0;
          _proofreadingDownloadMessage = 'Proofreading download started.';
          break;

        case 'progress':
          _proofreadingStatus = 'DOWNLOADING';
          _proofreadingDownloadedBytes = _readInteger(event['downloadedBytes']);
          _proofreadingTotalBytes =
              _readInteger(event['totalBytes']) ?? _proofreadingTotalBytes;
          _proofreadingDownloadMessage = 'Downloading proofreading assets…';
          break;

        case 'completed':
          _proofreadingStatus = 'AVAILABLE';
          _proofreadingDescription =
              'The dedicated Proofreading API is ready to use.';
          _proofreadingDownloadedBytes =
              _readInteger(event['downloadedBytes']) ?? _proofreadingTotalBytes;
          _proofreadingTotalBytes =
              _readInteger(event['totalBytes']) ?? _proofreadingTotalBytes;
          _proofreadingDownloadMessage =
              'Proofreading download completed successfully.';
          _proofreadingError = null;
          break;

        case 'failed':
          _proofreadingStatus = 'DOWNLOADABLE';
          _proofreadingDescription =
              'This device supports proofreading, but its assets are not ready.';
          _proofreadingDownloadMessage = null;
          _proofreadingError =
              '${event['message'] ?? 'Proofreading asset download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
          break;
      }
    });
  }

  void _handleImageDescriptionDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _imageDescriptionStatus = 'DOWNLOADING';
          _imageDescriptionDescription =
              'The required image-description assets are downloading.';
          _imageDescriptionTotalBytes = _readInteger(event['totalBytes']);
          _imageDescriptionDownloadedBytes = 0;
          _imageDescriptionDownloadMessage =
              'Image-description download started.';
          break;

        case 'progress':
          _imageDescriptionStatus = 'DOWNLOADING';
          _imageDescriptionDownloadedBytes = _readInteger(
            event['downloadedBytes'],
          );
          _imageDescriptionTotalBytes =
              _readInteger(event['totalBytes']) ?? _imageDescriptionTotalBytes;
          _imageDescriptionDownloadMessage =
              'Downloading image-description assets…';
          break;

        case 'completed':
          _imageDescriptionStatus = 'AVAILABLE';
          _imageDescriptionDescription =
              'The dedicated Image Description API is ready to use.';
          _imageDescriptionDownloadedBytes =
              _readInteger(event['downloadedBytes']) ??
              _imageDescriptionTotalBytes;
          _imageDescriptionTotalBytes =
              _readInteger(event['totalBytes']) ?? _imageDescriptionTotalBytes;
          _imageDescriptionDownloadMessage =
              'Image-description download completed successfully.';
          _imageDescriptionError = null;
          break;

        case 'failed':
          _imageDescriptionStatus = 'DOWNLOADABLE';
          _imageDescriptionDescription =
              'This device supports image description, but its assets are not ready.';
          _imageDescriptionDownloadMessage = null;
          _imageDescriptionError =
              '${event['message'] ?? 'Image-description asset download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
          break;
      }
    });
  }

  void _handleSpeechRecognitionDownloadEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _speechRecognitionStatus = 'DOWNLOADING';
          _speechRecognitionDescription =
              'The required speech-recognition assets are downloading.';
          _speechRecognitionTotalBytes = _readInteger(event['totalBytes']);
          _speechRecognitionDownloadedBytes = 0;
          _speechRecognitionDownloadMessage =
              'Speech-recognition download started.';
          break;

        case 'progress':
          _speechRecognitionStatus = 'DOWNLOADING';
          _speechRecognitionDownloadedBytes = _readInteger(
            event['downloadedBytes'],
          );
          _speechRecognitionTotalBytes =
              _readInteger(event['totalBytes']) ?? _speechRecognitionTotalBytes;
          _speechRecognitionDownloadMessage =
              'Downloading speech-recognition assets…';
          break;

        case 'completed':
          _speechRecognitionStatus = 'AVAILABLE';
          _speechRecognitionDescription =
              'Advanced en-US speech recognition is ready to use.';
          _speechRecognitionDownloadedBytes =
              _readInteger(event['downloadedBytes']) ??
              _speechRecognitionTotalBytes;
          _speechRecognitionTotalBytes =
              _readInteger(event['totalBytes']) ?? _speechRecognitionTotalBytes;
          _speechRecognitionDownloadMessage =
              'Speech-recognition download completed successfully.';
          _speechRecognitionError = null;
          break;

        case 'failed':
          _speechRecognitionStatus = 'DOWNLOADABLE';
          _speechRecognitionDescription =
              'This device supports Advanced en-US speech recognition, but its assets are not ready.';
          _speechRecognitionDownloadMessage = null;
          _speechRecognitionError =
              '${event['message'] ?? 'Speech-recognition asset download failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });
  }

  void _handleSpeechRecognitionEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    setState(() {
      switch (eventName) {
        case 'started':
          _isRunningSpeechRecognition = true;
          _speechRecognitionSessionStatus = 'Listening';
          _speechRecognitionPartialText = '';
          _speechRecognitionFinalText = '';
          _speechRecognitionElapsedMilliseconds = 0;
          _speechRecognitionError = null;
          break;

        case 'partial':
          _isRunningSpeechRecognition = true;
          _speechRecognitionSessionStatus = 'Listening';
          _speechRecognitionPartialText = event['text']?.toString() ?? '';
          _speechRecognitionFinalText =
              event['finalText']?.toString() ?? _speechRecognitionFinalText;
          _speechRecognitionElapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ??
              _speechRecognitionElapsedMilliseconds;
          break;

        case 'final':
          _isRunningSpeechRecognition = true;
          _speechRecognitionSessionStatus = 'Listening';
          _speechRecognitionFinalText =
              event['finalText']?.toString() ??
              event['text']?.toString() ??
              _speechRecognitionFinalText;
          _speechRecognitionPartialText = '';
          _speechRecognitionElapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ??
              _speechRecognitionElapsedMilliseconds;
          break;

        case 'stopping':
          _speechRecognitionSessionStatus = 'Stopping…';
          break;

        case 'completed':
          _isRunningSpeechRecognition = false;
          _isStoppingSpeechRecognition = false;
          _speechRecognitionSessionStatus = 'Completed';
          _speechRecognitionFinalText =
              event['finalText']?.toString() ?? _speechRecognitionFinalText;
          _speechRecognitionPartialText = '';
          _speechRecognitionElapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ??
              _speechRecognitionElapsedMilliseconds;
          break;

        case 'failed':
          _isRunningSpeechRecognition = false;
          _isStoppingSpeechRecognition = false;
          _speechRecognitionSessionStatus = 'Error';
          _speechRecognitionFinalText =
              event['finalText']?.toString() ?? _speechRecognitionFinalText;
          _speechRecognitionPartialText = '';
          _speechRecognitionElapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ??
              _speechRecognitionElapsedMilliseconds;
          _speechRecognitionError =
              '${event['message'] ?? 'Speech recognition failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });
  }

  void _handlePromptEvent(dynamic event) {
    if (!mounted || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();
    bool? promptRunSucceeded;

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
          _isRunningPrompt = _isRunningTopKComparison;
          promptRunSucceeded = true;
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
          _isRunningPrompt = _isRunningTopKComparison;
          promptRunSucceeded = false;
          _activeRunNumber = null;
          _promptStatus = 'Error';
          _elapsedMilliseconds = _readInteger(event['elapsedMilliseconds']);
          _promptError =
              '${event['message'] ?? 'Gemini Nano inference failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });

    if (promptRunSucceeded != null) {
      _completePromptRun(promptRunSucceeded!);
    }
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
    _completePromptRun(false);
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

  void _handleRewritingDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _rewritingDownloadMessage = null;
      _rewritingError = 'Rewriting download progress stream error: $error';
    });
  }

  void _handleProofreadingDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _proofreadingDownloadMessage = null;
      _proofreadingError =
          'Proofreading download progress stream error: $error';
    });
  }

  void _handleImageDescriptionDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _imageDescriptionDownloadMessage = null;
      _imageDescriptionError =
          'Image-description download progress stream error: $error';
    });
  }

  void _handleSpeechRecognitionDownloadStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _speechRecognitionDownloadMessage = null;
      _speechRecognitionError =
          'Speech-recognition download progress stream error: $error';
    });
  }

  void _handleSpeechRecognitionStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isRunningSpeechRecognition = false;
      _isStoppingSpeechRecognition = false;
      _speechRecognitionSessionStatus = 'Error';
      _speechRecognitionError =
          'Speech-recognition result stream error: $error';
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

  Color _rewritingStatusColor(ColorScheme colors) {
    switch (_rewritingStatus) {
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

  Color _proofreadingStatusColor(ColorScheme colors) {
    switch (_proofreadingStatus) {
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

  Color _imageDescriptionStatusColor(ColorScheme colors) {
    switch (_imageDescriptionStatus) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
      case 'CHECKING':
        return colors.primary;
      case 'UNAVAILABLE':
      case 'ERROR':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  Color _speechRecognitionStatusColor(ColorScheme colors) {
    switch (_speechRecognitionStatus) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
      case 'CHECKING':
        return colors.primary;
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

  void _jumpToSection(NanoLabSection section) {
    final GlobalKey sectionKey;

    switch (section) {
      case NanoLabSection.status:
        sectionKey = _statusSectionKey;
        break;
      case NanoLabSection.prompt:
        sectionKey = _promptSectionKey;
        break;
      case NanoLabSection.summarization:
        sectionKey = _summarizationSectionKey;
        break;
      case NanoLabSection.rewriting:
        sectionKey = _rewritingSectionKey;
        break;
      case NanoLabSection.proofreading:
        sectionKey = _proofreadingSectionKey;
        break;
      case NanoLabSection.imageDescription:
        sectionKey = _imageDescriptionSectionKey;
        break;
      case NanoLabSection.speechRecognition:
        sectionKey = _speechRecognitionSectionKey;
        break;
    }

    final sectionContext = sectionKey.currentContext;
    if (sectionContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  String _everydayTitle(NanoLabSection section) {
    switch (section) {
      case NanoLabSection.status:
        return 'Check Offline Readiness';
      case NanoLabSection.prompt:
        return 'Ask Gemini Nano';
      case NanoLabSection.summarization:
        return 'Summarize Something';
      case NanoLabSection.rewriting:
        return 'Rewrite a Message';
      case NanoLabSection.proofreading:
        return 'Fix My Writing';
      case NanoLabSection.imageDescription:
        return 'Understand a Picture';
      case NanoLabSection.speechRecognition:
        return 'Transcribe Speech';
    }
  }

  String _everydayIntroduction(NanoLabSection section) {
    switch (section) {
      case NanoLabSection.status:
        return 'Check whether Gemini Nano and its required on-device assets '
            'are ready before testing offline.';
      case NanoLabSection.prompt:
        return 'Give Gemini Nano a short instruction and review how well it '
            'follows it without using cloud AI.';
      case NanoLabSection.summarization:
        return 'Ask the dedicated on-device summarizer to shorten a fixed '
            'fictional article, then check what it kept or omitted.';
      case NanoLabSection.rewriting:
        return 'See whether Gemini Nano can make a fictional message sound '
            'more professional without changing its facts.';
      case NanoLabSection.proofreading:
        return 'See whether Gemini Nano can correct deliberate spelling and '
            'grammar mistakes while preserving the original meaning.';
      case NanoLabSection.imageDescription:
        return 'Ask Gemini Nano to describe a fixed image, then compare the '
            'description with what is actually visible.';
      case NanoLabSection.speechRecognition:
        return 'Speak the fixed phrase and check whether the on-device '
            'transcription preserves every important detail.';
    }
  }

  String _everydayMeaning(NanoLabSection section) {
    switch (section) {
      case NanoLabSection.status:
        return 'A supported phone may still need model or feature assets '
            'downloaded before offline use. AVAILABLE means this particular '
            'capability is ready now.';
      case NanoLabSection.prompt:
        return 'A fluent answer can still miss instructions or introduce '
            'unsupported details. Review the response rather than treating '
            'it as automatically correct.';
      case NanoLabSection.summarization:
        return 'On the Pixel 10 Pro, the dedicated summarizer was fast and '
            'factually sound but repeatedly omitted the article\'s central '
            'results.';
      case NanoLabSection.rewriting:
        return 'On the Pixel 10 Pro, rewriting preserved the supplied facts '
            'but repeatedly added an unrequested sign-off and name placeholder.';
      case NanoLabSection.proofreading:
        return 'On the Pixel 10 Pro, proofreading corrected every planted '
            'error, preserved all facts, added nothing, and averaged about '
            'one second.';
      case NanoLabSection.imageDescription:
        return 'Repeated wording does not guarantee complete recognition. In '
            'the fixed tests, Nano omitted one prominent object and '
            'misidentified another.';
      case NanoLabSection.speechRecognition:
        return 'Speech recognition usually preserved the complete meaning, '
            'but occasional meaningful substitutions make user review '
            'important.';
    }
  }

  IconData _everydayIcon(NanoLabSection section) {
    switch (section) {
      case NanoLabSection.status:
        return Icons.offline_bolt_outlined;
      case NanoLabSection.prompt:
        return Icons.chat_bubble_outline;
      case NanoLabSection.summarization:
        return Icons.summarize;
      case NanoLabSection.rewriting:
        return Icons.edit_note;
      case NanoLabSection.proofreading:
        return Icons.spellcheck;
      case NanoLabSection.imageDescription:
        return Icons.image_search;
      case NanoLabSection.speechRecognition:
        return Icons.mic_none;
    }
  }

  Color _everydayStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
      case 'CHECKING':
        return colors.primary;
      case 'UNAVAILABLE':
      case 'ERROR':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  Widget _buildEverydayReadinessCard({
    required String status,
    required String description,
    required bool isChecking,
    required VoidCallback onCheck,
    required bool isStartingDownload,
    required VoidCallback onDownload,
    String? error,
    String? downloadMessage,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _everydayStatusColor(status, colors);
    final progress =
        downloadedBytes != null && totalBytes != null && totalBytes > 0
        ? (downloadedBytes / totalBytes).clamp(0.0, 1.0).toDouble()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Readiness',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(height: 1.4)),
            if (downloadMessage != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(downloadMessage),
              if (downloadedBytes != null) ...[
                const SizedBox(height: 4),
                Text(
                  totalBytes != null && totalBytes > 0
                      ? '${_formatBytes(downloadedBytes)} of '
                            '${_formatBytes(totalBytes)}'
                      : _formatBytes(downloadedBytes),
                ),
              ],
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isChecking || isStartingDownload ? null : onCheck,
              icon: isChecking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(isChecking ? 'Checking…' : 'Check readiness'),
            ),
            if (status == 'DOWNLOADABLE') ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: isStartingDownload ? null : onDownload,
                icon: isStartingDownload
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  isStartingDownload
                      ? 'Starting download…'
                      : 'Download required assets',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayInputCard(String label, String input) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(input, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayResultCard({
    required String output,
    int? elapsedMilliseconds,
    String? status,
  }) {
    if (output.trim().isEmpty && elapsedMilliseconds == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Result',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (elapsedMilliseconds != null)
                  Text(_formatElapsedTime(elapsedMilliseconds)),
              ],
            ),
            if (status != null) ...[const SizedBox(height: 6), Text(status)],
            if (output.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(output, style: const TextStyle(height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayMeaningCard(NanoLabSection section) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What this means',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _everydayMeaning(section),
              style: TextStyle(
                color: colors.onSecondaryContainer,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayError(String? error) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }

  Widget _buildEverydayTestScreen(
    BuildContext context,
    NanoLabSection section,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_everydayTitle(section))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _everydayIcon(section),
                    size: 34,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _everydayTitle(section),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _everydayIntroduction(section),
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._buildEverydayTestContent(section),
            const SizedBox(height: 12),
            _buildEverydayMeaningCard(section),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TechnicalLabScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.science_outlined),
              label: const Text('Open Technical Lab for full controls'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEverydayTestContent(NanoLabSection section) {
    switch (section) {
      case NanoLabSection.status:
        return [
          _buildEverydayReadinessCard(
            status: _status,
            description: _description,
            isChecking: _isChecking,
            onCheck: _checkNanoStatus,
            isStartingDownload: _isStartingDownload,
            onDownload: _startDownload,
            error: _errorDetails,
            downloadMessage: _downloadMessage,
            downloadedBytes: _downloadedBytes,
            totalBytes: _totalBytes,
          ),
          if (_deviceInformation != null) ...[
            const SizedBox(height: 12),
            _buildEverydayInputCard('This device', _deviceInformation!),
          ],
        ];

      case NanoLabSection.prompt:
        return [
          _buildEverydayReadinessCard(
            status: _status,
            description: _description,
            isChecking: _isChecking,
            onCheck: _checkNanoStatus,
            isStartingDownload: _isStartingDownload,
            onDownload: _startDownload,
            error: _errorDetails,
            downloadMessage: _downloadMessage,
            downloadedBytes: _downloadedBytes,
            totalBytes: _totalBytes,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            enabled: !_isRunningPrompt,
            minLines: 3,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Your instruction',
              helperText: 'Keep it short and avoid sensitive information.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _status == 'AVAILABLE' &&
                    !_isRunningPrompt &&
                    _promptController.text.trim().isNotEmpty
                ? () => _runPrompt()
                : null,
            icon: _isRunningPrompt
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isRunningPrompt ? 'Generating…' : 'Run test'),
          ),
          const SizedBox(height: 12),
          _buildEverydayError(_promptError),
          _buildEverydayResultCard(
            output: _promptOutput,
            elapsedMilliseconds: _elapsedMilliseconds,
            status: _promptStatus,
          ),
        ];

      case NanoLabSection.summarization:
        return [
          _buildEverydayReadinessCard(
            status: _summarizationStatus,
            description: _summarizationDescription,
            isChecking: _isCheckingSummarization,
            onCheck: _checkSummarizationStatus,
            isStartingDownload: _isStartingSummarizationDownload,
            onDownload: _startSummarizationDownload,
            error: _summarizationError,
            downloadMessage: _summarizationDownloadMessage,
            downloadedBytes: _summarizationDownloadedBytes,
            totalBytes: _summarizationTotalBytes,
          ),
          const SizedBox(height: 12),
          _buildEverydayInputCard(
            'Fixed fictional article',
            _summarizationController.text,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _summarizationStatus == 'AVAILABLE' && !_isRunningSummarization
                ? _runSummarization
                : null,
            icon: _isRunningSummarization
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunningSummarization ? 'Summarizing…' : 'Run summary test',
            ),
          ),
          const SizedBox(height: 12),
          _buildEverydayResultCard(
            output: _summarizationOutput,
            elapsedMilliseconds: _summarizationElapsedMilliseconds,
          ),
        ];

      case NanoLabSection.rewriting:
        return [
          _buildEverydayReadinessCard(
            status: _rewritingStatus,
            description: _rewritingDescription,
            isChecking: _isCheckingRewriting,
            onCheck: _checkRewritingStatus,
            isStartingDownload: _isStartingRewritingDownload,
            onDownload: _startRewritingDownload,
            error: _rewritingError,
            downloadMessage: _rewritingDownloadMessage,
            downloadedBytes: _rewritingDownloadedBytes,
            totalBytes: _rewritingTotalBytes,
          ),
          const SizedBox(height: 12),
          _buildEverydayInputCard(
            'Fixed fictional message',
            _rewritingController.text,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _rewritingStatus == 'AVAILABLE' && !_isRunningRewriting
                ? _runRewriting
                : null,
            icon: _isRunningRewriting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunningRewriting ? 'Rewriting…' : 'Run rewriting test',
            ),
          ),
          const SizedBox(height: 12),
          _buildEverydayResultCard(
            output: _rewritingOutput,
            elapsedMilliseconds: _rewritingElapsedMilliseconds,
          ),
        ];

      case NanoLabSection.proofreading:
        return [
          _buildEverydayReadinessCard(
            status: _proofreadingStatus,
            description: _proofreadingDescription,
            isChecking: _isCheckingProofreading,
            onCheck: _checkProofreadingStatus,
            isStartingDownload: _isStartingProofreadingDownload,
            onDownload: _startProofreadingDownload,
            error: _proofreadingError,
            downloadMessage: _proofreadingDownloadMessage,
            downloadedBytes: _proofreadingDownloadedBytes,
            totalBytes: _proofreadingTotalBytes,
          ),
          const SizedBox(height: 12),
          _buildEverydayInputCard(
            'Sentence with deliberate mistakes',
            _proofreadingController.text,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _proofreadingStatus == 'AVAILABLE' && !_isRunningProofreading
                ? _runProofreading
                : null,
            icon: _isRunningProofreading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunningProofreading
                  ? 'Proofreading…'
                  : 'Run proofreading test',
            ),
          ),
          const SizedBox(height: 12),
          _buildEverydayResultCard(
            output: _proofreadingOutput,
            elapsedMilliseconds: _proofreadingElapsedMilliseconds,
          ),
        ];

      case NanoLabSection.imageDescription:
        final aspectRatio =
            _imageDescriptionTestImageWidth != null &&
                _imageDescriptionTestImageHeight != null &&
                _imageDescriptionTestImageHeight! > 0
            ? _imageDescriptionTestImageWidth! /
                  _imageDescriptionTestImageHeight!
            : 3 / 2;
        return [
          _buildEverydayReadinessCard(
            status: _imageDescriptionStatus,
            description: _imageDescriptionDescription,
            isChecking: _isCheckingImageDescription,
            onCheck: _checkImageDescriptionStatus,
            isStartingDownload: _isStartingImageDescriptionDownload,
            onDownload: _startImageDescriptionDownload,
            error: _imageDescriptionError,
            downloadMessage: _imageDescriptionDownloadMessage,
            downloadedBytes: _imageDescriptionDownloadedBytes,
            totalBytes: _imageDescriptionTotalBytes,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedImageDescriptionTestImageId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Fixed test image',
            ),
            items: const [
              DropdownMenuItem(
                value: _syntheticImageDescriptionTestImageId,
                child: Text('Synthetic house scene'),
              ),
              DropdownMenuItem(
                value: _realPhotoImageDescriptionTestImageId,
                child: Text('Real tabletop photograph'),
              ),
            ],
            onChanged:
                _isLoadingImageDescriptionTestImage ||
                    _isRunningImageDescription
                ? null
                : (value) {
                    if (value != null &&
                        value != _selectedImageDescriptionTestImageId) {
                      _selectImageDescriptionTestImage(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: _imageDescriptionTestImageBytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.memory(
                      _imageDescriptionTestImageBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _imageDescriptionStatus == 'AVAILABLE' &&
                    !_isRunningImageDescription &&
                    !_isLoadingImageDescriptionTestImage &&
                    _imageDescriptionTestImageBytes != null
                ? _runImageDescription
                : null,
            icon: _isRunningImageDescription
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunningImageDescription
                  ? 'Describing…'
                  : 'Describe this image',
            ),
          ),
          const SizedBox(height: 12),
          _buildEverydayResultCard(
            output: _imageDescriptionOutput,
            elapsedMilliseconds: _imageDescriptionElapsedMilliseconds,
          ),
        ];

      case NanoLabSection.speechRecognition:
        final transcript = _speechRecognitionFinalText.isNotEmpty
            ? _speechRecognitionFinalText
            : _speechRecognitionPartialText;
        return [
          _buildEverydayReadinessCard(
            status: _speechRecognitionStatus,
            description: _speechRecognitionDescription,
            isChecking: _isCheckingSpeechRecognition,
            onCheck: _checkSpeechRecognitionStatus,
            isStartingDownload: _isStartingSpeechRecognitionDownload,
            onDownload: _startSpeechRecognitionDownload,
            error: _speechRecognitionError,
            downloadMessage: _speechRecognitionDownloadMessage,
            downloadedBytes: _speechRecognitionDownloadedBytes,
            totalBytes: _speechRecognitionTotalBytes,
          ),
          const SizedBox(height: 12),
          _buildEverydayInputCard(
            'Fixed phrase to speak',
            _speechRecognitionTestPhrase,
          ),
          const SizedBox(height: 12),
          if (_isRunningSpeechRecognition)
            FilledButton.icon(
              onPressed: _isStoppingSpeechRecognition
                  ? null
                  : _stopSpeechRecognition,
              icon: _isStoppingSpeechRecognition
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.stop),
              label: Text(
                _isStoppingSpeechRecognition ? 'Stopping…' : 'Stop listening',
              ),
            )
          else
            FilledButton.icon(
              onPressed:
                  _speechRecognitionStatus == 'AVAILABLE' &&
                      !_isStartingSpeechRecognition
                  ? _startSpeechRecognition
                  : null,
              icon: _isStartingSpeechRecognition
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic),
              label: Text(
                _isStartingSpeechRecognition ? 'Starting…' : 'Start listening',
              ),
            ),
          const SizedBox(height: 12),
          _buildEverydayResultCard(
            output: transcript,
            elapsedMilliseconds: _speechRecognitionElapsedMilliseconds,
            status: _speechRecognitionSessionStatus,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final everydaySection = widget.initialSection;
    if (widget.everydayMode && everydaySection != null) {
      return _buildEverydayTestScreen(context, everydaySection);
    }

    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
    final summarizationStatusColor = _summarizationStatusColor(colors);
    final rewritingStatusColor = _rewritingStatusColor(colors);
    final proofreadingStatusColor = _proofreadingStatusColor(colors);
    final imageDescriptionStatusColor = _imageDescriptionStatusColor(colors);
    final speechRecognitionStatusColor = _speechRecognitionStatusColor(colors);
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
    final hasValidRewritingInput = _rewritingController.text.trim().isNotEmpty;
    final hasValidProofreadingInput = _proofreadingController.text
        .trim()
        .isNotEmpty;
    final imageDescriptionAspectRatio =
        _imageDescriptionTestImageWidth != null &&
            _imageDescriptionTestImageHeight != null &&
            _imageDescriptionTestImageHeight! > 0
        ? _imageDescriptionTestImageWidth! / _imageDescriptionTestImageHeight!
        : 3 / 2;
    final isOtherGenAiOperationInProgress =
        _isStartingDownload ||
        _isRunningPrompt ||
        _isStartingSummarizationDownload ||
        _isRunningSummarization ||
        _isStartingRewritingDownload ||
        _isRunningRewriting ||
        _isStartingProofreadingDownload ||
        _isRunningProofreading ||
        _isStartingImageDescriptionDownload ||
        _isRunningImageDescription;

    double? progress;
    double? summarizationProgress;
    double? rewritingProgress;
    double? proofreadingProgress;
    double? imageDescriptionProgress;
    double? speechRecognitionProgress;

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

    if (_rewritingDownloadedBytes != null &&
        _rewritingTotalBytes != null &&
        _rewritingTotalBytes! > 0) {
      rewritingProgress = (_rewritingDownloadedBytes! / _rewritingTotalBytes!)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    if (_proofreadingDownloadedBytes != null &&
        _proofreadingTotalBytes != null &&
        _proofreadingTotalBytes! > 0) {
      proofreadingProgress =
          (_proofreadingDownloadedBytes! / _proofreadingTotalBytes!)
              .clamp(0.0, 1.0)
              .toDouble();
    }

    if (_imageDescriptionDownloadedBytes != null &&
        _imageDescriptionTotalBytes != null &&
        _imageDescriptionTotalBytes! > 0) {
      imageDescriptionProgress =
          (_imageDescriptionDownloadedBytes! / _imageDescriptionTotalBytes!)
              .clamp(0.0, 1.0)
              .toDouble();
    }

    if (_speechRecognitionDownloadedBytes != null &&
        _speechRecognitionTotalBytes != null &&
        _speechRecognitionTotalBytes! > 0) {
      speechRecognitionProgress =
          (_speechRecognitionDownloadedBytes! / _speechRecognitionTotalBytes!)
              .clamp(0.0, 1.0)
              .toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Lab'),
        actions: [
          PopupMenuButton<NanoLabSection>(
            tooltip: 'Jump to test',
            onSelected: _jumpToSection,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: NanoLabSection.status,
                child: Row(
                  children: [
                    Icon(Icons.memory),
                    SizedBox(width: 12),
                    Text('Gemini Nano status'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.prompt,
                child: Row(
                  children: [
                    Icon(Icons.tune),
                    SizedBox(width: 12),
                    Text('Prompt and Top-K'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.summarization,
                child: Row(
                  children: [
                    Icon(Icons.summarize),
                    SizedBox(width: 12),
                    Text('Summarization'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.rewriting,
                child: Row(
                  children: [
                    Icon(Icons.edit_note),
                    SizedBox(width: 12),
                    Text('Rewriting'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.proofreading,
                child: Row(
                  children: [
                    Icon(Icons.spellcheck),
                    SizedBox(width: 12),
                    Text('Proofreading'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.imageDescription,
                child: Row(
                  children: [
                    Icon(Icons.image_search),
                    SizedBox(width: 12),
                    Text('Image description'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NanoLabSection.speechRecognition,
                child: Row(
                  children: [
                    Icon(Icons.mic_none),
                    SizedBox(width: 12),
                    Text('Speech recognition'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt),
                  SizedBox(width: 6),
                  Text('Tests'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gemini Nano status',
                key: _statusSectionKey,
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
                        _isStartingSummarizationDownload ||
                        _isRunningRewriting ||
                        _isStartingRewritingDownload ||
                        _isRunningProofreading ||
                        _isStartingProofreadingDownload ||
                        _isRunningImageDescription ||
                        _isStartingImageDescriptionDownload
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
                        _isStartingSummarizationDownload ||
                        _isRunningRewriting ||
                        _isStartingRewritingDownload ||
                        _isRunningProofreading ||
                        _isStartingProofreadingDownload ||
                        _isRunningImageDescription ||
                        _isStartingImageDescriptionDownload
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
                          _isRunningSummarization ||
                          _isStartingRewritingDownload ||
                          _isRunningRewriting ||
                          _isStartingProofreadingDownload ||
                          _isRunningProofreading ||
                          _isStartingImageDescriptionDownload ||
                          _isRunningImageDescription
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
                key: _promptSectionKey,
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
                        !_isRunningRewriting &&
                        !_isStartingRewritingDownload &&
                        !_isRunningProofreading &&
                        !_isStartingProofreadingDownload &&
                        !_isRunningImageDescription &&
                        !_isStartingImageDescriptionDownload &&
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Top-K comparison',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Runs the current prompt three times with Top-K 1, 3, '
                        'and 10. Temperature stays at 0.7, seed at 123, and '
                        'candidate count at 1 so Top-K is the only setting '
                        'that changes.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed:
                            _status == 'AVAILABLE' &&
                                !_isRunningPrompt &&
                                !_isRunningSummarization &&
                                !_isRunningRewriting &&
                                !_isRunningProofreading &&
                                !_isRunningImageDescription &&
                                hasValidMaxOutputTokens &&
                                _promptController.text.trim().isNotEmpty
                            ? _runTopKComparison
                            : null,
                        icon: _isRunningTopKComparison
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.compare_arrows),
                        label: Text(
                          _isRunningTopKComparison
                              ? 'Running ${_topKComparisonStep ?? 1} of 3…'
                              : 'Run Top-K comparison',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed:
                    !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        !_isRunningRewriting &&
                        !_isRunningProofreading &&
                        !_isRunningImageDescription &&
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
                key: _summarizationSectionKey,
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
                        _isStartingDownload ||
                        _isRunningRewriting ||
                        _isStartingRewritingDownload ||
                        _isRunningProofreading ||
                        _isStartingProofreadingDownload ||
                        _isRunningImageDescription ||
                        _isStartingImageDescriptionDownload
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
                          _isRunningSummarization ||
                          _isStartingRewritingDownload ||
                          _isRunningRewriting ||
                          _isStartingProofreadingDownload ||
                          _isRunningProofreading ||
                          _isStartingImageDescriptionDownload ||
                          _isRunningImageDescription
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
                        !_isRunningRewriting &&
                        !_isRunningProofreading &&
                        !_isRunningImageDescription &&
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
              const SizedBox(height: 40),
              Text(
                'Dedicated rewriting test',
                key: _rewritingSectionKey,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uses the ML Kit Rewriting API with fixed English professional '
                'output. Official input limit: fewer than 256 tokens.',
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
                          color: rewritingStatusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rewritingStatusColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _rewritingStatus,
                            style: TextStyle(
                              color: rewritingStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_rewritingDescription),
                      if (_rewritingError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _rewritingError!,
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
                    _isCheckingRewriting ||
                        _isStartingRewritingDownload ||
                        _isRunningRewriting ||
                        _isRunningPrompt ||
                        _isRunningSummarization ||
                        _isStartingDownload ||
                        _isStartingSummarizationDownload ||
                        _isRunningProofreading ||
                        _isStartingProofreadingDownload ||
                        _isRunningImageDescription ||
                        _isStartingImageDescriptionDownload
                    ? null
                    : _checkRewritingStatus,
                icon: _isCheckingRewriting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_note),
                label: Text(
                  _isCheckingRewriting ? 'Checking…' : 'Check rewriting status',
                ),
              ),
              if (_rewritingStatus == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingRewritingDownload ||
                          _isStartingDownload ||
                          _isStartingSummarizationDownload ||
                          _isRunningPrompt ||
                          _isRunningSummarization ||
                          _isRunningRewriting ||
                          _isStartingProofreadingDownload ||
                          _isRunningProofreading ||
                          _isStartingImageDescriptionDownload ||
                          _isRunningImageDescription
                      ? null
                      : _startRewritingDownload,
                  icon: _isStartingRewritingDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingRewritingDownload
                        ? 'Starting download…'
                        : 'Download rewriting assets',
                  ),
                ),
              ],
              if (_rewritingDownloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(value: rewritingProgress),
                        const SizedBox(height: 12),
                        Text(_rewritingDownloadMessage!),
                        if (_rewritingDownloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _rewritingTotalBytes != null &&
                                    _rewritingTotalBytes! > 0
                                ? '${_formatBytes(_rewritingDownloadedBytes!)} of '
                                      '${_formatBytes(_rewritingTotalBytes!)}'
                                : _formatBytes(_rewritingDownloadedBytes!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Text to rewrite:'),
              const SizedBox(height: 12),
              TextField(
                controller: _rewritingController,
                enabled: !_isRunningRewriting,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText:
                      '${_rewritingController.text.length} characters · keep under 256 tokens',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _rewritingStatus == 'AVAILABLE' &&
                        !_isRunningRewriting &&
                        !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        !_isRunningProofreading &&
                        !_isRunningImageDescription &&
                        hasValidRewritingInput
                    ? _runRewriting
                    : null,
                icon: _isRunningRewriting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunningRewriting ? 'Rewriting…' : 'Rewrite professionally',
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
                        'Status: ${_isRunningRewriting
                            ? 'Rewriting…'
                            : _rewritingError != null
                            ? 'Error'
                            : _rewritingOutput.isNotEmpty
                            ? 'Completed'
                            : 'Not run'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_rewritingElapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Processing time: '
                          '${_formatElapsedTime(_rewritingElapsedMilliseconds!)}',
                        ),
                      ],
                      if (_rewritingSuggestionCount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Suggestions returned: $_rewritingSuggestionCount '
                          '(showing highest confidence)',
                        ),
                      ],
                      if (_submittedRewritingInput != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact input sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedRewritingInput!),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Output:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _rewritingOutput.isEmpty
                            ? 'The professional rewrite will appear here.'
                            : _rewritingOutput,
                      ),
                      if (_rewritingError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _rewritingError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Dedicated proofreading test',
                key: _proofreadingSectionKey,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uses the ML Kit Proofreading API with fixed English keyboard '
                'input. Official input limit: fewer than 256 tokens.',
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
                          color: proofreadingStatusColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: proofreadingStatusColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _proofreadingStatus,
                            style: TextStyle(
                              color: proofreadingStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_proofreadingDescription),
                      if (_proofreadingError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _proofreadingError!,
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
                    _isCheckingProofreading ||
                        _isStartingProofreadingDownload ||
                        _isRunningProofreading ||
                        _isRunningPrompt ||
                        _isRunningSummarization ||
                        _isRunningRewriting ||
                        _isStartingDownload ||
                        _isStartingSummarizationDownload ||
                        _isStartingRewritingDownload ||
                        _isRunningImageDescription ||
                        _isStartingImageDescriptionDownload
                    ? null
                    : _checkProofreadingStatus,
                icon: _isCheckingProofreading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.spellcheck),
                label: Text(
                  _isCheckingProofreading
                      ? 'Checking…'
                      : 'Check proofreading status',
                ),
              ),
              if (_proofreadingStatus == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingProofreadingDownload ||
                          _isStartingDownload ||
                          _isStartingSummarizationDownload ||
                          _isStartingRewritingDownload ||
                          _isRunningPrompt ||
                          _isRunningSummarization ||
                          _isRunningRewriting ||
                          _isRunningProofreading ||
                          _isStartingImageDescriptionDownload ||
                          _isRunningImageDescription
                      ? null
                      : _startProofreadingDownload,
                  icon: _isStartingProofreadingDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingProofreadingDownload
                        ? 'Starting download…'
                        : 'Download proofreading assets',
                  ),
                ),
              ],
              if (_proofreadingDownloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(value: proofreadingProgress),
                        const SizedBox(height: 12),
                        Text(_proofreadingDownloadMessage!),
                        if (_proofreadingDownloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _proofreadingTotalBytes != null &&
                                    _proofreadingTotalBytes! > 0
                                ? '${_formatBytes(_proofreadingDownloadedBytes!)} of '
                                      '${_formatBytes(_proofreadingTotalBytes!)}'
                                : _formatBytes(_proofreadingDownloadedBytes!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Text to proofread:'),
              const SizedBox(height: 12),
              TextField(
                controller: _proofreadingController,
                enabled: !_isRunningProofreading,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText:
                      '${_proofreadingController.text.length} characters · keep under 256 tokens',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _proofreadingStatus == 'AVAILABLE' &&
                        !_isRunningProofreading &&
                        !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        !_isRunningRewriting &&
                        !_isRunningImageDescription &&
                        hasValidProofreadingInput
                    ? _runProofreading
                    : null,
                icon: _isRunningProofreading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunningProofreading ? 'Proofreading…' : 'Proofread text',
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
                        'Status: ${_isRunningProofreading
                            ? 'Proofreading…'
                            : _proofreadingError != null
                            ? 'Error'
                            : _proofreadingOutput.isNotEmpty
                            ? 'Completed'
                            : 'Not run'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_proofreadingElapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Processing time: '
                          '${_formatElapsedTime(_proofreadingElapsedMilliseconds!)}',
                        ),
                      ],
                      if (_proofreadingSuggestionCount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Suggestions returned: $_proofreadingSuggestionCount '
                          '(showing highest confidence)',
                        ),
                      ],
                      if (_submittedProofreadingInput != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact input sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedProofreadingInput!),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Output:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _proofreadingOutput.isEmpty
                            ? 'The proofread text will appear here.'
                            : _proofreadingOutput,
                      ),
                      if (_proofreadingError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _proofreadingError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Dedicated image description test',
                key: _imageDescriptionSectionKey,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uses the ML Kit Image Description API with two fixed local '
                'images: a controlled synthetic scene and a real tabletop '
                'photo. The API returns one short English description.',
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
                          color: imageDescriptionStatusColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: imageDescriptionStatusColor,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _imageDescriptionStatus,
                            style: TextStyle(
                              color: imageDescriptionStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_imageDescriptionDescription),
                      if (_imageDescriptionError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _imageDescriptionError!,
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
                    _isCheckingImageDescription ||
                        _isStartingImageDescriptionDownload ||
                        _isRunningImageDescription ||
                        _isRunningPrompt ||
                        _isRunningSummarization ||
                        _isRunningRewriting ||
                        _isRunningProofreading ||
                        _isStartingDownload ||
                        _isStartingSummarizationDownload ||
                        _isStartingRewritingDownload ||
                        _isStartingProofreadingDownload
                    ? null
                    : _checkImageDescriptionStatus,
                icon: _isCheckingImageDescription
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_search),
                label: Text(
                  _isCheckingImageDescription
                      ? 'Checking…'
                      : 'Check image description status',
                ),
              ),
              if (_imageDescriptionStatus == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingImageDescriptionDownload ||
                          _isStartingDownload ||
                          _isStartingSummarizationDownload ||
                          _isStartingRewritingDownload ||
                          _isStartingProofreadingDownload ||
                          _isRunningPrompt ||
                          _isRunningSummarization ||
                          _isRunningRewriting ||
                          _isRunningProofreading ||
                          _isRunningImageDescription
                      ? null
                      : _startImageDescriptionDownload,
                  icon: _isStartingImageDescriptionDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingImageDescriptionDownload
                        ? 'Starting download…'
                        : 'Download image-description assets',
                  ),
                ),
              ],
              if (_imageDescriptionDownloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_imageDescriptionStatus == 'DOWNLOADING' ||
                            _isStartingImageDescriptionDownload) ...[
                          LinearProgressIndicator(
                            value: imageDescriptionProgress,
                          ),
                          const SizedBox(height: 12),
                        ] else if (_imageDescriptionStatus == 'AVAILABLE') ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(_imageDescriptionDownloadMessage!),
                        if (_imageDescriptionDownloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _imageDescriptionTotalBytes != null &&
                                    _imageDescriptionTotalBytes! > 0
                                ? '${_formatBytes(_imageDescriptionDownloadedBytes!)} of '
                                      '${_formatBytes(_imageDescriptionTotalBytes!)}'
                                : _formatBytes(
                                    _imageDescriptionDownloadedBytes!,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedImageDescriptionTestImageId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Test image',
                ),
                items: const [
                  DropdownMenuItem(
                    value: _syntheticImageDescriptionTestImageId,
                    child: Text('Synthetic house scene'),
                  ),
                  DropdownMenuItem(
                    value: _realPhotoImageDescriptionTestImageId,
                    child: Text('Real tabletop photo'),
                  ),
                ],
                onChanged:
                    _isRunningImageDescription ||
                        _isLoadingImageDescriptionTestImage
                    ? null
                    : (value) {
                        if (value != null &&
                            value != _selectedImageDescriptionTestImageId) {
                          _selectImageDescriptionTestImage(value);
                        }
                      },
              ),
              const SizedBox(height: 24),
              const Text('Selected fixed test image:'),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: _imageDescriptionTestImageBytes == null
                    ? const AspectRatio(
                        aspectRatio: 3 / 2,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : AspectRatio(
                        aspectRatio: imageDescriptionAspectRatio,
                        child: Image.memory(
                          _imageDescriptionTestImageBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                'Image ID: ${_imageDescriptionTestImageId ?? 'loading'} · '
                '${_imageDescriptionTestImageWidth ?? '—'}×'
                '${_imageDescriptionTestImageHeight ?? '—'}',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _imageDescriptionStatus == 'AVAILABLE' &&
                        _imageDescriptionTestImageBytes != null &&
                        !_isLoadingImageDescriptionTestImage &&
                        !_isRunningImageDescription &&
                        !_isRunningPrompt &&
                        !_isRunningSummarization &&
                        !_isRunningRewriting &&
                        !_isRunningProofreading
                    ? _runImageDescription
                    : null,
                icon: _isRunningImageDescription
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunningImageDescription
                      ? 'Describing image…'
                      : 'Describe selected image',
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
                        'Status: ${_isRunningImageDescription
                            ? 'Describing…'
                            : _imageDescriptionError != null
                            ? 'Error'
                            : _imageDescriptionOutput.isNotEmpty
                            ? 'Completed'
                            : 'Not run'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_imageDescriptionElapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Processing time: '
                          '${_formatElapsedTime(_imageDescriptionElapsedMilliseconds!)}',
                        ),
                      ],
                      if (_imageDescriptionTestImageId != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact image sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_imageDescriptionTestImageId · '
                          '$_imageDescriptionTestImageWidth×'
                          '$_imageDescriptionTestImageHeight',
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Output:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _imageDescriptionOutput.isEmpty
                            ? 'The short image description will appear here.'
                            : _imageDescriptionOutput,
                      ),
                      if (_imageDescriptionError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _imageDescriptionError!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Dedicated speech recognition test',
                key: _speechRecognitionSectionKey,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Uses the ML Kit GenAI Speech Recognition API in Advanced '
                'mode with the en-US locale and live microphone input. Speak '
                'the fixed phrase below, then stop the session.',
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
                          color: speechRecognitionStatusColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: speechRecognitionStatusColor,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _speechRecognitionStatus,
                            style: TextStyle(
                              color: speechRecognitionStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(_speechRecognitionDescription),
                      const SizedBox(height: 8),
                      const Text('Mode: Advanced · Locale: en-US'),
                      if (_speechRecognitionError != null) ...[
                        const SizedBox(height: 16),
                        SelectableText(
                          _speechRecognitionError!,
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
                    _isCheckingSpeechRecognition ||
                        _isStartingSpeechRecognitionDownload ||
                        _isStartingSpeechRecognition ||
                        _isRunningSpeechRecognition ||
                        isOtherGenAiOperationInProgress
                    ? null
                    : _checkSpeechRecognitionStatus,
                icon: _isCheckingSpeechRecognition
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic_none),
                label: Text(
                  _isCheckingSpeechRecognition
                      ? 'Checking…'
                      : 'Check speech recognition status',
                ),
              ),
              if (_speechRecognitionStatus == 'DOWNLOADABLE') ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed:
                      _isStartingSpeechRecognitionDownload ||
                          _isStartingSpeechRecognition ||
                          _isRunningSpeechRecognition ||
                          isOtherGenAiOperationInProgress
                      ? null
                      : _startSpeechRecognitionDownload,
                  icon: _isStartingSpeechRecognitionDownload
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isStartingSpeechRecognitionDownload
                        ? 'Starting download…'
                        : 'Download speech-recognition assets',
                  ),
                ),
              ],
              if (_speechRecognitionDownloadMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_speechRecognitionStatus == 'DOWNLOADING' ||
                            _isStartingSpeechRecognitionDownload) ...[
                          LinearProgressIndicator(
                            value: speechRecognitionProgress,
                          ),
                          const SizedBox(height: 12),
                        ] else if (_speechRecognitionStatus == 'AVAILABLE') ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(_speechRecognitionDownloadMessage!),
                        if (_speechRecognitionDownloadedBytes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _speechRecognitionTotalBytes != null &&
                                    _speechRecognitionTotalBytes! > 0
                                ? '${_formatBytes(_speechRecognitionDownloadedBytes!)} of '
                                      '${_formatBytes(_speechRecognitionTotalBytes!)}'
                                : _formatBytes(
                                    _speechRecognitionDownloadedBytes!,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Fixed phrase to speak:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SelectableText(_speechRecognitionTestPhrase),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed:
                        _speechRecognitionStatus == 'AVAILABLE' &&
                            !_isStartingSpeechRecognition &&
                            !_isStoppingSpeechRecognition &&
                            !_isRunningSpeechRecognition &&
                            !_isStartingSpeechRecognitionDownload &&
                            !isOtherGenAiOperationInProgress
                        ? _startSpeechRecognition
                        : null,
                    icon: _isStartingSpeechRecognition
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mic),
                    label: Text(
                      _isStartingSpeechRecognition
                          ? 'Starting…'
                          : 'Start listening',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _isRunningSpeechRecognition &&
                            !_isStoppingSpeechRecognition
                        ? _stopSpeechRecognition
                        : null,
                    icon: _isStoppingSpeechRecognition
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop),
                    label: Text(
                      _isStoppingSpeechRecognition ? 'Stopping…' : 'Stop',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Status: $_speechRecognitionSessionStatus',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_speechRecognitionElapsedMilliseconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Session time: '
                          '${_formatElapsedTime(_speechRecognitionElapsedMilliseconds!)}',
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Final committed transcription:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _speechRecognitionFinalText.isEmpty
                            ? 'No final text yet.'
                            : _speechRecognitionFinalText,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Live partial transcription:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _speechRecognitionPartialText.isEmpty
                            ? (_isRunningSpeechRecognition
                                  ? 'Listening for speech…'
                                  : 'No partial text.')
                            : _speechRecognitionPartialText,
                        style: TextStyle(color: colors.secondary),
                      ),
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
