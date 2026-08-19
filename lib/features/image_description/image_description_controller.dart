import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../services/nano_native_service.dart';

class ImageDescriptionController extends ChangeNotifier {
  ImageDescriptionController({required this._nativeService}) {
    _downloadSubscription = _nativeService.imageDescriptionDownloadEvents
        .listen(_handleDownloadEvent, onError: _handleDownloadStreamError);
    loadTestImage();
  }

  static const syntheticTestImageId = 'synthetic_house_scene_v1';
  static const realPhotoTestImageId = 'real_tabletop_photo_v1';

  final NanoNativeService _nativeService;
  late final StreamSubscription<dynamic> _downloadSubscription;

  bool isChecking = false;
  bool isStartingDownload = false;
  bool isRunning = false;
  bool isLoadingTestImage = false;

  String status = 'NOT CHECKED';
  String description =
      'Check whether the dedicated ML Kit Image Description API is available.';
  String? error;
  String? downloadMessage;
  String selectedTestImageId = syntheticTestImageId;
  Uint8List? testImageBytes;
  String? testImageId;
  int? testImageWidth;
  int? testImageHeight;
  String output = '';
  int? downloadedBytes;
  int? totalBytes;
  int? elapsedMilliseconds;

  bool _isDisposed = false;

  Future<void> loadTestImage({String? imageId}) async {
    final requestedImageId = imageId ?? selectedTestImageId;

    _change(() {
      isLoadingTestImage = true;
      testImageBytes = null;
      testImageId = null;
      testImageWidth = null;
      testImageHeight = null;
      error = null;
    });

    try {
      final result = await _nativeService.getImageDescriptionTestImage(
        requestedImageId,
      );

      if (_isDisposed) {
        return;
      }

      final imageBytes = result?['imageBytes'];
      if (result == null || imageBytes is! Uint8List) {
        _change(() {
          error = 'Kotlin returned no valid image-description test image.';
        });
        return;
      }

      if (result['imageId']?.toString() != requestedImageId) {
        _change(() {
          error = 'Kotlin returned a different image-description test image.';
        });
        return;
      }

      _change(() {
        testImageBytes = imageBytes;
        testImageId = result['imageId']?.toString();
        testImageWidth = _readInteger(result['width']);
        testImageHeight = _readInteger(result['height']);
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        error =
            '${platformError.message ?? 'The fixed image-description test scene could not be loaded.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        error =
            'Unexpected image-description test-image error: $unexpectedError';
      });
    } finally {
      if (!_isDisposed) {
        _change(() {
          isLoadingTestImage = false;
        });
      }
    }
  }

  Future<void> selectTestImage(String imageId) async {
    _change(() {
      selectedTestImageId = imageId;
      output = '';
      elapsedMilliseconds = null;
      error = null;
    });

    await loadTestImage(imageId: imageId);
  }

  Future<void> checkStatus() async {
    _change(() {
      isChecking = true;
      status = 'CHECKING';
      description =
          'Checking the dedicated Image Description API configuration…';
      error = null;
    });

    try {
      final result = await _nativeService.getImageDescriptionStatus();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          status = 'ERROR';
          description =
              'Kotlin returned no image-description status information.';
        });
        return;
      }

      _change(() {
        status = result['status']?.toString() ?? 'UNKNOWN';
        description =
            result['description']?.toString() ??
            'No image-description status description was returned.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description =
            platformError.message ??
            'Image-description status detection failed.';
        error = 'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'ERROR';
        description = 'Unexpected image-description status-check failure.';
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
      downloadMessage = 'Requesting the image-description asset download…';
      downloadedBytes = null;
      totalBytes = null;
      error = null;
    });

    try {
      await _nativeService.startImageDescriptionDownload();

      if (_isDisposed) {
        return;
      }

      _change(() {
        status = 'DOWNLOADING';
        description = 'The required image-description assets are downloading.';
      });
    } on PlatformException catch (platformError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error =
            '${platformError.message ?? 'The image-description download could not be started.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      if (_isDisposed) {
        return;
      }

      _change(() {
        downloadMessage = null;
        error = 'Unexpected image-description download error: $unexpectedError';
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
    final stopwatch = Stopwatch()..start();

    _change(() {
      isRunning = true;
      output = '';
      elapsedMilliseconds = null;
      error = null;
    });

    try {
      final result = await _nativeService.runImageDescription(
        selectedTestImageId,
      );
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      if (result == null) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error = 'Kotlin returned no image-description result.';
        });
        return;
      }

      final nativeImageId = result['imageId']?.toString();
      final nativeWidth = _readInteger(result['width']);
      final nativeHeight = _readInteger(result['height']);
      if (nativeImageId != testImageId ||
          nativeWidth != testImageWidth ||
          nativeHeight != testImageHeight) {
        _change(() {
          elapsedMilliseconds = stopwatch.elapsedMilliseconds;
          error =
              'The native inference image did not match the displayed test image.';
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
            '${platformError.message ?? 'Gemini Nano image description failed.'}\n'
            'Platform error: ${platformError.code}';
      });
    } catch (unexpectedError) {
      stopwatch.stop();

      if (_isDisposed) {
        return;
      }

      _change(() {
        elapsedMilliseconds = stopwatch.elapsedMilliseconds;
        error = 'Unexpected image-description error: $unexpectedError';
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
          description =
              'The required image-description assets are downloading.';
          totalBytes = _readInteger(event['totalBytes']);
          downloadedBytes = 0;
          downloadMessage = 'Image-description download started.';
          break;
        case 'progress':
          status = 'DOWNLOADING';
          downloadedBytes = _readInteger(event['downloadedBytes']);
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage = 'Downloading image-description assets…';
          break;
        case 'completed':
          status = 'AVAILABLE';
          description = 'The dedicated Image Description API is ready to use.';
          downloadedBytes =
              _readInteger(event['downloadedBytes']) ?? totalBytes;
          totalBytes = _readInteger(event['totalBytes']) ?? totalBytes;
          downloadMessage =
              'Image-description download completed successfully.';
          error = null;
          break;
        case 'failed':
          status = 'DOWNLOADABLE';
          description =
              'This device supports image description, but its assets are not ready.';
          downloadMessage = null;
          error =
              '${event['message'] ?? 'Image-description asset download failed.'}\n'
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
      error = 'Image-description download progress stream error: $streamError';
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
    super.dispose();
  }
}
