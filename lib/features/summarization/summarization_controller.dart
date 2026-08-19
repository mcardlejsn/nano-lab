import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../services/nano_native_service.dart';

class SummarizationController extends ChangeNotifier {
  SummarizationController({required this._nativeService})
    : inputController = TextEditingController(text: defaultInput) {
    _downloadSubscription = _nativeService.summarizationDownloadEvents.listen(
      _handleDownloadEvent,
      onError: _handleDownloadStreamError,
    );
  }

  static const defaultInput =
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

  final NanoNativeService _nativeService;
  final TextEditingController inputController;
  late final StreamSubscription<dynamic> _downloadSubscription;

  bool isChecking = false;
  bool isStartingDownload = false;
  bool isRunning = false;

  String status = 'NOT CHECKED';
  String description =
      'Check whether the dedicated ML Kit Summarization API is available.';
  String? error;
  String? downloadMessage;
  String? submittedInput;
  String output = '';
  int? downloadedBytes;
  int? totalBytes;
  int? elapsedMilliseconds;

  bool _isDisposed = false;

  void inputChanged() {
    _change(() {});
  }

  Future<void> checkStatus() async {
    _change(() {
      isChecking = true;
      status = 'CHECKING';
      description = 'Checking the dedicated Summarization API configuration…';
      error = null;
    });

    try {
      final result = await _nativeService.getSummarizationStatus();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          status = 'ERROR';
          description = 'Kotlin returned no summarization status information.';
        });
        return;
      }

      _change(() {
        status = result['status']?.toString() ?? 'UNKNOWN';
        description =
            result['description']?.toString() ??
            'No summarization status description was returned.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description =
            platformError.message ?? 'Summarization status detection failed.';
        error = 'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description = 'Unexpected summarization status-check failure.';
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
      downloadMessage = 'Requesting the summarization asset download…';
      downloadedBytes = null;
      totalBytes = null;
      error = null;
    });

    try {
      await _nativeService.startSummarizationDownload();

      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'DOWNLOADING';
        description = 'The required summarization assets are downloading.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error =
            '${platformError.message ?? 'The summarization download could not be started.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error = 'Unexpected summarization download error: $unexpectedError';
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
      error = null;
    });

    try {
      final result = await _nativeService.runSummarization(input);
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error = 'Kotlin returned no summarization result.';
        });
        return;
      }

      final nativeInput = result['input']?.toString();
      if (nativeInput != input) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error =
              'The native summarization input did not match the displayed input.';
        });
        return;
      }

      _change(() {
        output = result['output']?.toString() ?? '';
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
            '${platformError.message ?? 'Gemini Nano summarization failed.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      _change(() {
        elapsedMilliseconds = stopwatch.elapsedMilliseconds;
        error = 'Unexpected summarization error: $unexpectedError';
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
          description = 'The required summarization assets are downloading.';
          totalBytes = _readInteger(event['totalBytes']);
          downloadedBytes = 0;
          downloadMessage = 'Summarization download started.';
          break;

        case 'progress':
          status = 'DOWNLOADING';
          downloadedBytes = _readInteger(event['downloadedBytes']);
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Downloading summarization assets…';
          break;

        case 'completed':
          status = 'AVAILABLE';
          description = 'The dedicated Summarization API is ready to use.';
          downloadedBytes =
              _readInteger(event['downloadedBytes']) ?? totalBytes;
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Summarization download completed successfully.';
          error = null;
          break;

        case 'failed':
          status = 'DOWNLOADABLE';
          description =
              'This device supports summarization, but its assets are not ready.';
          downloadMessage = null;
          error =
              '${event['message'] ?? 'Summarization asset download failed.'}\n'
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
      error = 'Summarization download progress stream error: $streamError';
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
