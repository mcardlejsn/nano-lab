import 'package:flutter/material.dart';

import 'speech_recognition_controller.dart';

enum SpeechRecognitionPresentation { technical, everyday }

class SpeechRecognitionExperiment extends StatelessWidget {
  const SpeechRecognitionExperiment({
    super.key,
    required this.controller,
    required this.presentation,
    this.sectionKey,
    this.blockStatusActions = false,
    this.blockStart = false,
  });

  final SpeechRecognitionController controller;
  final SpeechRecognitionPresentation presentation;
  final Key? sectionKey;
  final bool blockStatusActions;
  final bool blockStart;

  @override
  Widget build(BuildContext context) {
    return presentation == SpeechRecognitionPresentation.technical
        ? _buildTechnical(context)
        : _buildEveryday(context);
  }

  Widget _buildTechnical(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dedicated speech recognition test',
          key: sectionKey,
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
                      controller.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(controller.description),
                const SizedBox(height: 8),
                const Text('Mode: Advanced · Locale: en-US'),
                if (controller.error != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    controller.error!,
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
              controller.isChecking ||
                  controller.isStartingDownload ||
                  controller.isStarting ||
                  controller.isRunning ||
                  blockStatusActions
              ? null
              : controller.checkStatus,
          icon: controller.isChecking
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mic_none),
          label: Text(
            controller.isChecking
                ? 'Checking…'
                : 'Check speech recognition status',
          ),
        ),
        if (controller.status == 'DOWNLOADABLE') ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed:
                controller.isStartingDownload ||
                    controller.isStarting ||
                    controller.isRunning ||
                    blockStatusActions
                ? null
                : controller.startDownload,
            icon: controller.isStartingDownload
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(
              controller.isStartingDownload
                  ? 'Starting download…'
                  : 'Download speech-recognition assets',
            ),
          ),
        ],
        if (controller.downloadMessage != null) ...[
          const SizedBox(height: 16),
          _buildDownloadCard(),
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
            child: SelectableText(SpeechRecognitionController.testPhrase),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed:
                  controller.status == 'AVAILABLE' &&
                      !controller.isStarting &&
                      !controller.isStopping &&
                      !controller.isRunning &&
                      !controller.isStartingDownload &&
                      !blockStart
                  ? controller.start
                  : null,
              icon: controller.isStarting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic),
              label: Text(
                controller.isStarting ? 'Starting…' : 'Start listening',
              ),
            ),
            OutlinedButton.icon(
              onPressed: controller.isRunning && !controller.isStopping
                  ? controller.stop
                  : null,
              icon: controller.isStopping
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.stop),
              label: Text(controller.isStopping ? 'Stopping…' : 'Stop'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTechnicalResultCard(context),
      ],
    );
  }

  Widget _buildEveryday(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEverydayReadinessCard(context),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fixed phrase to speak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const SelectableText(
                  SpeechRecognitionController.testPhrase,
                  style: TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.isRunning)
          FilledButton.icon(
            onPressed: controller.isStopping ? null : controller.stop,
            icon: controller.isStopping
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop),
            label: Text(controller.isStopping ? 'Stopping…' : 'Stop listening'),
          )
        else
          FilledButton.icon(
            onPressed:
                controller.status == 'AVAILABLE' && !controller.isStarting
                ? controller.start
                : null,
            icon: controller.isStarting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mic),
            label: Text(
              controller.isStarting ? 'Starting…' : 'Start listening',
            ),
          ),
        const SizedBox(height: 12),
        _buildEverydayResultCard(context),
      ],
    );
  }

  Widget _buildDownloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.status == 'DOWNLOADING' ||
                controller.isStartingDownload) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 12),
            ] else if (controller.status == 'AVAILABLE') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(height: 12),
            ],
            Text(controller.downloadMessage!),
            if (controller.downloadedBytes != null) ...[
              const SizedBox(height: 8),
              Text(_downloadSizeText),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalResultCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: ${controller.sessionStatus}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (controller.elapsedMilliseconds != null) ...[
              const SizedBox(height: 8),
              Text(
                'Session time: '
                '${_formatElapsedTime(controller.elapsedMilliseconds!)}',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Final committed transcription:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              controller.finalText.isEmpty
                  ? 'No final text yet.'
                  : controller.finalText,
            ),
            const SizedBox(height: 16),
            const Text(
              'Live partial transcription:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              controller.partialText.isEmpty
                  ? (controller.isRunning
                        ? 'Listening for speech…'
                        : 'No partial text.')
                  : controller.partialText,
              style: TextStyle(color: colors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayReadinessCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
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
                    controller.status,
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
            Text(controller.description, style: const TextStyle(height: 1.4)),
            if (controller.downloadMessage != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(controller.downloadMessage!),
              if (controller.downloadedBytes != null) ...[
                const SizedBox(height: 4),
                Text(_downloadSizeText),
              ],
            ],
            if (controller.error != null) ...[
              const SizedBox(height: 12),
              Text(controller.error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.isChecking || controller.isStartingDownload
                  ? null
                  : controller.checkStatus,
              icon: controller.isChecking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                controller.isChecking ? 'Checking…' : 'Check readiness',
              ),
            ),
            if (controller.status == 'DOWNLOADABLE') ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: controller.isStartingDownload
                    ? null
                    : controller.startDownload,
                icon: controller.isStartingDownload
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  controller.isStartingDownload
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

  Widget _buildEverydayResultCard(BuildContext context) {
    if (controller.transcript.trim().isEmpty &&
        controller.elapsedMilliseconds == null) {
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
                if (controller.elapsedMilliseconds != null)
                  Text(_formatElapsedTime(controller.elapsedMilliseconds!)),
              ],
            ),
            const SizedBox(height: 6),
            Text(controller.sessionStatus),
            if (controller.transcript.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                controller.transcript,
                style: const TextStyle(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? get _progress {
    final downloaded = controller.downloadedBytes;
    final total = controller.totalBytes;
    return downloaded != null && total != null && total > 0
        ? (downloaded / total).clamp(0.0, 1.0).toDouble()
        : null;
  }

  String get _downloadSizeText {
    final downloaded = controller.downloadedBytes!;
    final total = controller.totalBytes;
    return total != null && total > 0
        ? '${_formatBytes(downloaded)} of ${_formatBytes(total)}'
        : _formatBytes(downloaded);
  }

  Color _statusColor(ColorScheme colors) {
    switch (controller.status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
      case 'CHECKING':
        return presentation == SpeechRecognitionPresentation.everyday
            ? colors.primary
            : controller.status == 'DOWNLOADING'
            ? Colors.blue
            : colors.primary;
      case 'UNAVAILABLE':
      case 'ERROR':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  String _formatBytes(int bytes) {
    const bytesPerMiB = 1024 * 1024;
    return '${(bytes / bytesPerMiB).toStringAsFixed(1)} MiB';
  }

  String _formatElapsedTime(int milliseconds) {
    return '${(milliseconds / 1000).toStringAsFixed(2)} seconds';
  }
}
