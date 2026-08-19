import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../services/nano_native_service.dart';

class SpeechRecognitionController extends ChangeNotifier {
  SpeechRecognitionController({required this._nativeService}) {
    _downloadSubscription = _nativeService.speechRecognitionDownloadEvents
        .listen(_handleDownloadEvent, onError: _handleDownloadStreamError);
    _recognitionSubscription = _nativeService.speechRecognitionEvents.listen(
      _handleRecognitionEvent,
      onError: _handleRecognitionStreamError,
    );
  }

  static const testPhrase =
      'On Monday, August seventeenth, twenty twenty-six, the fictional '
      'Northbridge office received seventeen packages. Three were labeled '
      'incorrectly and must be checked by Friday at four fifteen P.M.';

  final NanoNativeService _nativeService;
  late final StreamSubscription<dynamic> _downloadSubscription;
  late final StreamSubscription<dynamic> _recognitionSubscription;

  bool isChecking = false;
  bool isStartingDownload = false;
  bool isStarting = false;
  bool isStopping = false;
  bool isRunning = false;

  String status = 'NOT CHECKED';
  String description =
      'Check whether Advanced en-US speech recognition is available.';
  String sessionStatus = 'Not run';
  String? error;
  String? downloadMessage;
  String partialText = '';
  String finalText = '';
  int? downloadedBytes;
  int? totalBytes;
  int? elapsedMilliseconds;

  bool _isDisposed = false;

  String get transcript => finalText.isNotEmpty ? finalText : partialText;

  Future<void> checkStatus() async {
    _change(() {
      isChecking = true;
      status = 'CHECKING';
      description =
          'Checking the Advanced en-US speech-recognition configuration…';
      error = null;
    });

    try {
      final result = await _nativeService.getSpeechRecognitionStatus();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          status = 'ERROR';
          description =
              'Kotlin returned no speech-recognition status information.';
        });
        return;
      }

      _change(() {
        status = result['status']?.toString() ?? 'UNKNOWN';
        description =
            result['description']?.toString() ??
            'No speech-recognition status description was returned.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description =
            platformError.message ??
            'Speech-recognition status detection failed.';
        error = 'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description = 'Unexpected speech-recognition status-check failure.';
        error = unexpectedError.toString();
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isChecking = false;
        });
      }
    }
  }

  Future<void> startDownload() async {
    _change(() {
      isStartingDownload = true;
      downloadMessage = 'Requesting the speech-recognition asset download…';
      downloadedBytes = null;
      totalBytes = null;
      error = null;
    });

    try {
      await _nativeService.startSpeechRecognitionDownload();

      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'DOWNLOADING';
        description = 'The required speech-recognition assets are downloading.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error =
            '${platformError.message ?? 'The speech-recognition download could not be started.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error =
            'Unexpected speech-recognition download error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isStartingDownload = false;
        });
      }
    }
  }

  Future<void> start() async {
    _change(() {
      isStarting = true;
      sessionStatus = 'Requesting microphone permission…';
      partialText = '';
      finalText = '';
      elapsedMilliseconds = null;
      error = null;
    });

    try {
      final permissionResult = await _nativeService
          .requestSpeechRecognitionPermission();

      if (_isDisposed) {
        return;
      }

      if (permissionResult?['granted'] != true) {
        _change(() {
          sessionStatus = 'Permission denied';
          error =
              'Microphone permission is required for the live speech test. '
              'You can allow it in Android app settings and try again.';
        });
        return;
      }

      _change(() {
        sessionStatus = 'Starting microphone…';
      });

      await _nativeService.startSpeechRecognition();
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        sessionStatus = 'Error';
        isRunning = false;
        error =
            '${platformError.message ?? 'Speech recognition could not be started.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        sessionStatus = 'Error';
        isRunning = false;
        error = 'Unexpected speech-recognition start error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isStarting = false;
        });
      }
    }
  }

  Future<void> stop() async {
    _change(() {
      isStopping = true;
      sessionStatus = 'Stopping…';
      error = null;
    });

    try {
      await _nativeService.stopSpeechRecognition();
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        sessionStatus = 'Stop failed';
        error =
            '${platformError.message ?? 'Speech recognition could not be stopped.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        sessionStatus = 'Stop failed';
        error = 'Unexpected speech-recognition stop error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isStopping = false;
        });
      }
    }
  }

  void _handleDownloadEvent(dynamic event) {
    if (_isDisposed || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    _change(() {
      switch (eventName) {
        case 'started':
          status = 'DOWNLOADING';
          description =
              'The required speech-recognition assets are downloading.';
          totalBytes = _readInteger(event['totalBytes']);
          downloadedBytes = 0;
          downloadMessage = 'Speech-recognition download started.';
          break;
        case 'progress':
          status = 'DOWNLOADING';
          downloadedBytes = _readInteger(event['downloadedBytes']);
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Downloading speech-recognition assets…';
          break;
        case 'completed':
          status = 'AVAILABLE';
          description = 'Advanced en-US speech recognition is ready to use.';
          downloadedBytes =
              _readInteger(event['downloadedBytes']) ?? totalBytes;
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage =
              'Speech-recognition download completed successfully.';
          error = null;
          break;
        case 'failed':
          status = 'DOWNLOADABLE';
          description =
              'This device supports Advanced en-US speech recognition, but its assets are not ready.';
          downloadMessage = null;
          error =
              '${event['message'] ?? 'Speech-recognition asset download failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });
  }

  void _handleRecognitionEvent(dynamic event) {
    if (_isDisposed || event is! Map) {
      return;
    }

    final eventName = event['event']?.toString();

    _change(() {
      switch (eventName) {
        case 'started':
          isRunning = true;
          sessionStatus = 'Listening';
          partialText = '';
          finalText = '';
          elapsedMilliseconds = 0;
          error = null;
          break;
        case 'partial':
          isRunning = true;
          sessionStatus = 'Listening';
          partialText = event['text']?.toString() ?? '';
          finalText = event['finalText']?.toString() ?? finalText;
          elapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ?? elapsedMilliseconds;
          break;
        case 'final':
          isRunning = true;
          sessionStatus = 'Listening';
          finalText =
              event['finalText']?.toString() ??
              event['text']?.toString() ??
              finalText;
          partialText = '';
          elapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ?? elapsedMilliseconds;
          break;
        case 'stopping':
          sessionStatus = 'Stopping…';
          break;
        case 'completed':
          isRunning = false;
          isStopping = false;
          sessionStatus = 'Completed';
          finalText = event['finalText']?.toString() ?? finalText;
          partialText = '';
          elapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ?? elapsedMilliseconds;
          break;
        case 'failed':
          isRunning = false;
          isStopping = false;
          sessionStatus = 'Error';
          finalText = event['finalText']?.toString() ?? finalText;
          partialText = '';
          elapsedMilliseconds =
              _readInteger(event['elapsedMilliseconds']) ?? elapsedMilliseconds;
          error =
              '${event['message'] ?? 'Speech recognition failed.'}'
              '${event['errorCode'] == null ? '' : '\nGenAI error code: ${event['errorCode']}'}';
          break;
      }
    });
  }

  void _handleDownloadStreamError(Object streamError) {
    if (_isDisposed) {
      return;
    }

    _change(() {
      downloadMessage = null;
      error = 'Speech-recognition download progress stream error: $streamError';
    });
  }

  void _handleRecognitionStreamError(Object streamError) {
    if (_isDisposed) {
      return;
    }

    _change(() {
      isRunning = false;
      isStopping = false;
      sessionStatus = 'Error';
      error = 'Speech-recognition result stream error: $streamError';
    });
  }

  void _change(VoidCallback change) {
    if (_isDisposed) {
      return;
    }

    change();
    notifyListeners();
  }

  int? _readInteger(dynamic value) => value is int ? value : null;

  @override
  void dispose() {
    _isDisposed = true;
    _downloadSubscription.cancel();
    _recognitionSubscription.cancel();
    super.dispose();
  }
}
