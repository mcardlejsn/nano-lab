import 'package:flutter/material.dart';

import 'image_description_controller.dart';

enum ImageDescriptionPresentation { technical, everyday }

class ImageDescriptionExperiment extends StatelessWidget {
  const ImageDescriptionExperiment({
    super.key,
    required this.controller,
    required this.presentation,
    this.sectionKey,
    this.blockStatusActions = false,
    this.blockRun = false,
  });

  final ImageDescriptionController controller;
  final ImageDescriptionPresentation presentation;
  final Key? sectionKey;
  final bool blockStatusActions;
  final bool blockRun;

  @override
  Widget build(BuildContext context) {
    return presentation == ImageDescriptionPresentation.technical
        ? _buildTechnical(context)
        : _buildEveryday(context);
  }

  Widget _buildTechnical(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colors);
    final progress = _progress;
    final aspectRatio = _aspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dedicated image description test',
          key: sectionKey,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Uses the ML Kit Image Description API with two fixed local '
          'images: a controlled synthetic scene and a real tabletop '
          'photo. The API returns one short English description.',
        ),
        const SizedBox(height: 20),
        _buildStatusCard(context, statusColor),
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
              : const Icon(Icons.image_search),
          label: Text(
            controller.isChecking
                ? 'Checking…'
                : 'Check image description status',
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
                  : 'Download image-description assets',
            ),
          ),
        ],
        if (controller.downloadMessage != null) ...[
          const SizedBox(height: 16),
          _buildDownloadCard(progress),
        ],
        const SizedBox(height: 24),
        _buildImageSelector(labelText: 'Test image'),
        const SizedBox(height: 24),
        const Text('Selected fixed test image:'),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: controller.testImageBytes == null
              ? const AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Center(child: CircularProgressIndicator()),
                )
              : AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Image.memory(
                    controller.testImageBytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Image ID: ${controller.testImageId ?? 'loading'} · '
          '${controller.testImageWidth ?? '—'}×'
          '${controller.testImageHeight ?? '—'}',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              controller.status == 'AVAILABLE' &&
                  controller.testImageBytes != null &&
                  !controller.isLoadingTestImage &&
                  !controller.isRunning &&
                  !blockRun
              ? controller.run
              : null,
          icon: controller.isRunning
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            controller.isRunning
                ? 'Describing image…'
                : 'Describe selected image',
          ),
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
        _buildImageSelector(labelText: 'Fixed test image', everyday: true),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: controller.testImageBytes == null
                ? const Center(child: CircularProgressIndicator())
                : Image.memory(
                    controller.testImageBytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
              controller.status == 'AVAILABLE' &&
                  !controller.isRunning &&
                  !controller.isLoadingTestImage &&
                  controller.testImageBytes != null
              ? controller.run
              : null,
          icon: controller.isRunning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            controller.isRunning ? 'Describing…' : 'Describe this image',
          ),
        ),
        const SizedBox(height: 12),
        _buildEverydayResultCard(context),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, Color statusColor) {
    final colors = Theme.of(context).colorScheme;
    return Card(
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
    );
  }

  Widget _buildImageSelector({
    required String labelText,
    bool everyday = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: controller.selectedTestImageId,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
      ),
      items: [
        const DropdownMenuItem(
          value: ImageDescriptionController.syntheticTestImageId,
          child: Text('Synthetic house scene'),
        ),
        DropdownMenuItem(
          value: ImageDescriptionController.realPhotoTestImageId,
          child: Text(
            everyday ? 'Real tabletop photograph' : 'Real tabletop photo',
          ),
        ),
      ],
      onChanged: controller.isLoadingTestImage || controller.isRunning
          ? null
          : (value) {
              if (value != null && value != controller.selectedTestImageId) {
                controller.selectTestImage(value);
              }
            },
    );
  }

  Widget _buildDownloadCard(double? progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.status == 'DOWNLOADING' ||
                controller.isStartingDownload) ...[
              LinearProgressIndicator(value: progress),
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
              'Status: ${controller.isRunning
                  ? 'Describing…'
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
            if (controller.testImageId != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Exact image sent:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${controller.testImageId} · ${controller.testImageWidth}×'
                '${controller.testImageHeight}',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              controller.output.isEmpty
                  ? 'The short image description will appear here.'
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

  double get _aspectRatio {
    final width = controller.testImageWidth;
    final height = controller.testImageHeight;
    return width != null && height != null && height > 0
        ? width / height
        : 3 / 2;
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
        return presentation == ImageDescriptionPresentation.everyday
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
