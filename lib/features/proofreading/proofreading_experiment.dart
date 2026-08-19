import 'package:flutter/material.dart';

import 'proofreading_controller.dart';

enum ProofreadingPresentation { technical, everyday }

class ProofreadingExperiment extends StatelessWidget {
  const ProofreadingExperiment({
    super.key,
    required this.controller,
    required this.presentation,
    this.sectionKey,
    this.blockStatusActions = false,
    this.blockRun = false,
  });

  final ProofreadingController controller;
  final ProofreadingPresentation presentation;
  final Key? sectionKey;
  final bool blockStatusActions;
  final bool blockRun;

  @override
  Widget build(BuildContext context) {
    switch (presentation) {
      case ProofreadingPresentation.technical:
        return _buildTechnical(context);
      case ProofreadingPresentation.everyday:
        return _buildEveryday(context);
    }
  }

  Widget _buildTechnical(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
    final hasValidInput = controller.inputController.text.trim().isNotEmpty;
    final progress =
        controller.downloadedBytes != null &&
            controller.totalBytes != null &&
            controller.totalBytes! > 0
        ? (controller.downloadedBytes! / controller.totalBytes!)
              .clamp(0.0, 1.0)
              .toDouble()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dedicated proofreading test',
          key: sectionKey,
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
                  controller.isRunning ||
                  blockStatusActions
              ? null
              : controller.checkStatus,
          icon: controller.isChecking
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.spellcheck),
          label: Text(
            controller.isChecking ? 'Checking…' : 'Check proofreading status',
          ),
        ),
        if (controller.status == 'DOWNLOADABLE') ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed:
                controller.isStartingDownload ||
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
                  : 'Download proofreading assets',
            ),
          ),
        ],
        if (controller.downloadMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(controller.downloadMessage!),
                  if (controller.downloadedBytes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      controller.totalBytes != null &&
                              controller.totalBytes! > 0
                          ? '${_formatBytes(controller.downloadedBytes!)} of '
                                '${_formatBytes(controller.totalBytes!)}'
                          : _formatBytes(controller.downloadedBytes!),
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
          controller: controller.inputController,
          enabled: !controller.isRunning,
          minLines: 4,
          maxLines: 8,
          onChanged: (_) => controller.inputChanged(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText:
                '${controller.inputController.text.length} characters · '
                'keep under 256 tokens',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              controller.status == 'AVAILABLE' &&
                  !controller.isRunning &&
                  !blockRun &&
                  hasValidInput
              ? controller.run
              : null,
          icon: controller.isRunning
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            controller.isRunning ? 'Proofreading…' : 'Proofread text',
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
                  'Status: ${controller.isRunning
                      ? 'Proofreading…'
                      : controller.error != null
                      ? 'Error'
                      : controller.output.isNotEmpty
                      ? 'Completed'
                      : 'Not run'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (controller.elapsedMilliseconds != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Processing time: '
                    '${_formatElapsedTime(controller.elapsedMilliseconds!)}',
                  ),
                ],
                if (controller.suggestionCount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Suggestions returned: ${controller.suggestionCount} '
                    '(showing highest confidence)',
                  ),
                ],
                if (controller.submittedInput != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Exact input sent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(controller.submittedInput!),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Output:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  controller.output.isEmpty
                      ? 'The proofread text will appear here.'
                      : controller.output,
                ),
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
      ],
    );
  }

  Widget _buildEveryday(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEverydayReadinessCard(context),
        const SizedBox(height: 12),
        _buildEverydayInputCard(context),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: controller.status == 'AVAILABLE' && !controller.isRunning
              ? controller.run
              : null,
          icon: controller.isRunning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            controller.isRunning ? 'Proofreading…' : 'Run proofreading test',
          ),
        ),
        const SizedBox(height: 12),
        _buildEverydayResultCard(context),
      ],
    );
  }

  Widget _buildEverydayReadinessCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
    final progress =
        controller.downloadedBytes != null &&
            controller.totalBytes != null &&
            controller.totalBytes! > 0
        ? (controller.downloadedBytes! / controller.totalBytes!)
              .clamp(0.0, 1.0)
              .toDouble()
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
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(controller.downloadMessage!),
              if (controller.downloadedBytes != null) ...[
                const SizedBox(height: 4),
                Text(
                  controller.totalBytes != null && controller.totalBytes! > 0
                      ? '${_formatBytes(controller.downloadedBytes!)} of '
                            '${_formatBytes(controller.totalBytes!)}'
                      : _formatBytes(controller.downloadedBytes!),
                ),
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

  Widget _buildEverydayInputCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sentence with deliberate mistakes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(
              controller.inputController.text,
              style: const TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayResultCard(BuildContext context) {
    if (controller.output.trim().isEmpty &&
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
            if (controller.output.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                controller.output,
                style: const TextStyle(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme colors) {
    switch (controller.status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'DOWNLOADABLE':
        return Colors.orange;
      case 'DOWNLOADING':
        return presentation == ProofreadingPresentation.everyday
            ? colors.primary
            : Colors.blue;
      case 'CHECKING':
        return presentation == ProofreadingPresentation.everyday
            ? colors.primary
            : colors.outline;
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
