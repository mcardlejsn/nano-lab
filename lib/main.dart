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

  static const _defaultPrompt =
      'Write exactly three short sentences about a fictional robot learning '
      'to garden.';

  static const _defaultSystemInstruction =
      'Respond using uppercase letters only.';

  late final TextEditingController _promptController;
  late final TextEditingController _systemInstructionController;

  late final StreamSubscription<dynamic> _downloadSubscription;
  late final StreamSubscription<dynamic> _promptSubscription;

  bool _isChecking = false;
  bool _isStartingDownload = false;
  bool _isRunningPrompt = false;
  bool _systemInstructionAvailable = false;

  String _status = 'NOT CHECKED';
  String _description =
      'Tap the button to ask AICore for the current Prompt API status.';

  String _promptStatus = 'Not run';
  String _promptOutput = '';
  String? _submittedPrompt;
  String? _submittedSystemInstruction;

  String? _deviceInformation;
  String? _systemInstructionDescription;
  String? _systemInstructionError;
  String? _errorDetails;
  String? _downloadMessage;
  String? _promptError;

  int? _downloadedBytes;
  int? _totalBytes;
  int? _elapsedMilliseconds;

  @override
  void initState() {
    super.initState();

    _promptController = TextEditingController(text: _defaultPrompt);
    _systemInstructionController = TextEditingController(
      text: _defaultSystemInstruction,
    );

    _downloadSubscription = _downloadChannel.receiveBroadcastStream().listen(
      _handleDownloadEvent,
      onError: _handleDownloadStreamError,
    );

    _promptSubscription = _promptChannel.receiveBroadcastStream().listen(
      _handlePromptEvent,
      onError: _handlePromptStreamError,
    );
  }

  @override
  void dispose() {
    _downloadSubscription.cancel();
    _promptSubscription.cancel();
    _promptController.dispose();
    _systemInstructionController.dispose();
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

  Future<void> _runPrompt() async {
    final prompt = _promptController.text;
    final systemInstruction = _systemInstructionController.text;
    final systemInstructionToSend = systemInstruction.trim().isEmpty
        ? null
        : systemInstruction;

    setState(() {
      _isRunningPrompt = true;
      _promptStatus = 'Starting…';
      _promptOutput = '';
      _submittedPrompt = prompt;
      _submittedSystemInstruction = systemInstructionToSend;
      _promptError = null;
      _elapsedMilliseconds = null;
    });

    try {
      final result = await _nativeChannel.invokeMapMethod<String, dynamic>(
        'runPrompt',
        <String, dynamic>{
          'prompt': prompt,
          'systemInstruction': systemInstruction,
        },
      );

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

      if (nativePrompt != prompt ||
          nativeSystemInstruction != systemInstructionToSend) {
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
            '${error.message ?? 'Gemini Nano inference could not be started.'}\n'
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
      _promptError = null;
      _elapsedMilliseconds = null;
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
          _submittedPrompt = event['prompt']?.toString();
          _submittedSystemInstruction =
              event['systemInstruction']?.toString();
          _promptError = null;
          _elapsedMilliseconds = null;
          break;

        case 'chunk':
          _promptStatus = 'Generating…';
          _promptOutput += event['text']?.toString() ?? '';
          break;

        case 'completed':
          _isRunningPrompt = false;
          _promptStatus = 'Completed';
          _elapsedMilliseconds = _readInteger(event['elapsedMilliseconds']);
          break;

        case 'failed':
          _isRunningPrompt = false;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);

    double? progress;

    if (_downloadedBytes != null && _totalBytes != null && _totalBytes! > 0) {
      progress = (_downloadedBytes! / _totalBytes!).clamp(0.0, 1.0).toDouble();
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
                onPressed: _isChecking || _isStartingDownload
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
                  onPressed: _isStartingDownload ? null : _startDownload,
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
                enabled:
                    _systemInstructionAvailable && !_isRunningPrompt,
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
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    _status == 'AVAILABLE' &&
                        !_isRunningPrompt &&
                        _promptController.text.trim().isNotEmpty
                    ? _runPrompt
                    : null,
                icon: _isRunningPrompt
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunningPrompt ? 'Generating…' : 'Run prompt',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    !_isRunningPrompt &&
                        (_promptOutput.isNotEmpty ||
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
                      if (_submittedPrompt != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exact system instruction sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _submittedSystemInstruction ?? 'None',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Exact prompt sent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(_submittedPrompt!),
                      ],
                      const SizedBox(height: 16),
                      SelectableText(
                        _promptOutput.isEmpty
                            ? 'Streaming output will appear here.'
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
            ],
          ),
        ),
      ),
    );
  }
}
