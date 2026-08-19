import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../services/nano_native_service.dart';

class RewritingController extends ChangeNotifier {
  RewritingController({required this._nativeService})
    : inputController = TextEditingController(text: defaultInput) {
    _downloadSubscription = _nativeService.rewritingDownloadEvents.listen(
      _handleDownloadEvent,
      onError: _handleDownloadStreamError,
    );
  }

  static const defaultInput =
      'hey sam, the fictional Alder Cove tool library opens Tuesday at 4:00 '
      'PM, and the town council votes on permanent funding October 12, 2026. '
      'please send me the inventory list by Friday so I can check it.';

  final NanoNativeService _nativeService;
  final TextEditingController inputController;
  late final StreamSubscription<dynamic> _downloadSubscription;

  bool isChecking = false;
  bool isStartingDownload = false;
  bool isRunning = false;

  String status = 'NOT CHECKED';
  String description =
      'Check whether the dedicated ML Kit Rewriting API is available.';
  String? error;
  String? downloadMessage;
  String? submittedInput;
  String output = '';
  int? downloadedBytes;
  int? totalBytes;
  int? elapsedMilliseconds;
  int? suggestionCount;

  bool _isDisposed = false;

  void inputChanged() {
    _change(() {});
  }

  Future<void> checkStatus() async {
    _change(() {
      isChecking = true;
      status = 'CHECKING';
      description = 'Checking the dedicated Rewriting API configuration…';
      error = null;
    });

    try {
      final result = await _nativeService.getRewritingStatus();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          status = 'ERROR';
          description = 'Kotlin returned no rewriting status information.';
        });
        return;
      }

      _change(() {
        status = result['status']?.toString() ?? 'UNKNOWN';
        description =
            result['description']?.toString() ??
            'No rewriting status description was returned.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description =
            platformError.message ?? 'Rewriting status detection failed.';
        error = 'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description = 'Unexpected rewriting status-check failure.';
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
      downloadMessage = 'Requesting the rewriting asset download…';
      downloadedBytes = null;
      totalBytes = null;
      error = null;
    });

    try {
      await _nativeService.startRewritingDownload();

      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'DOWNLOADING';
        description = 'The required rewriting assets are downloading.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error =
            '${platformError.message ?? 'The rewriting download could not be started.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error = 'Unexpected rewriting download error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isStartingDownload = false;
        });
      }
    }
  }

  Future<void> run() async {
    final input = inputController.text;
    final stopwatch = Stopwatch()..start();

    _change(() {
      isRunning = true;
      submittedInput = input;
      output = '';
      elapsedMilliseconds = null;
      suggestionCount = null;
      error = null;
    });

    try {
      final result = await _nativeService.runRewriting(input);
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error = 'Kotlin returned no rewriting result.';
        });
        return;
      }

      final nativeInput = result['input']?.toString();
      if (nativeInput != input) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error =
              'The native rewriting input did not match the displayed input.';
        });
        return;
      }

      _change(() {
        output = result['output']?.toString() ?? '';
        suggestionCount = _readInteger(result['suggestionCount']);
        elapsedMilliseconds =
            _readInteger(result['elapsedMilliseconds']) ??
            stopwatch.elapsedMilliseconds;
      });
    } on PlatformException catch (platformError) {
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      final details = platformError.details;
      final nativeElapsedMilliseconds = details is Map
          ? _readInteger(details['elapsedMilliseconds'])
          : null;

      _change(() {
        elapsedMilliseconds =
            nativeElapsedMilliseconds ?? stopwatch.elapsedMilliseconds;
        error =
            '${platformError.message ?? 'Gemini Nano rewriting failed.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      _change(() {
        elapsedMilliseconds = stopwatch.elapsedMilliseconds;
        error = 'Unexpected rewriting error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isRunning = false;
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
          description = 'The required rewriting assets are downloading.';
          totalBytes = _readInteger(event['totalBytes']);
          downloadedBytes = 0;
          downloadMessage = 'Rewriting download started.';
          break;

        case 'progress':
          status = 'DOWNLOADING';
          downloadedBytes = _readInteger(event['downloadedBytes']);
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Downloading rewriting assets…';
          break;

        case 'completed':
          status = 'AVAILABLE';
          description = 'The dedicated Rewriting API is ready to use.';
          downloadedBytes =
              _readInteger(event['downloadedBytes']) ?? totalBytes;
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Rewriting download completed successfully.';
          error = null;
          break;

        case 'failed':
          status = 'DOWNLOADABLE';
          description =
              'This device supports rewriting, but its assets are not ready.';
          downloadMessage = null;
          error =
              '${event['message'] ?? 'Rewriting asset download failed.'}\n'
              'GenAI error code: ${event['errorCode'] ?? 'unknown'}';
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
      error = 'Rewriting download progress stream error: $streamError';
    });
  }

  void _change(VoidCallback change) {
    if (_isDisposed) {
      return;
    }

    change();
    notifyListeners();
  }

  int? _readInteger(dynamic value) {
    return value is int ? value : null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _downloadSubscription.cancel();
    inputController.dispose();
    super.dispose();
  }
}
