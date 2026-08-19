import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/memory_snapshot.dart';
import '../../services/nano_native_service.dart';
import 'memory_experiment_controller.dart';

class MemoryExperimentScreen extends StatefulWidget {
  const MemoryExperimentScreen({
    super.key,
    this.nativeService = const NanoNativeService(),
  });

  final NanoNativeService nativeService;

  @override
  State<MemoryExperimentScreen> createState() => _MemoryExperimentScreenState();
}

class _MemoryExperimentScreenState extends State<MemoryExperimentScreen> {
  late final MemoryExperimentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemoryExperimentController(
      nativeService: widget.nativeService,
    )..addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: _controller.exportJson()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memory snapshots copied as JSON.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Memory Experiment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.memory,
                      color: colors.onPrimaryContainer,
                      size: 34,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Test the claim—do not assume it',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These snapshots directly measure Android system memory '
                      'and Nano Lab’s own process. They do not directly measure '
                      'AICore or prove that approximately 3 GB is reserved.',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildProtocolCard(context),
            const SizedBox(height: 16),
            _buildCaptureCard(context),
            if (_controller.error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _controller.error!,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ),
            ],
            if (_controller.snapshots.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Captured snapshots',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${_controller.snapshots.length}'),
                ],
              ),
              const SizedBox(height: 12),
              for (
                var index = 0;
                index < _controller.snapshots.length;
                index++
              ) ...[
                _buildSnapshotCard(
                  context,
                  _controller.snapshots[index],
                  index + 1,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _copyJson,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _controller.clear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear snapshots'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _buildAdbCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controlled sequence',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Restart the phone, open Nano Lab, and capture immediately.\n'
              '2. Check Nano/AICore availability, return here, and capture.\n'
              '3. Run the same fixed prompt once, return, and capture.\n'
              '4. Run that prompt five times total, then capture.\n'
              '5. Leave the phone idle for a fixed period and capture again.\n'
              '6. Use ADB for system-wide, AICore, and post-close snapshots.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use the same brightness, network state, background apps, idle '
              'duration, prompt, and run count on both phones.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Capture an in-app snapshot',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _controller.selectedStage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Experiment stage',
              ),
              items: MemoryExperimentController.stages
                  .map(
                    (stage) => DropdownMenuItem<String>(
                      value: stage,
                      child: Text(
                        stage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _controller.isCapturing
                  ? null
                  : (stage) {
                      if (stage != null) {
                        _controller.selectStage(stage);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller.noteController,
              enabled: !_controller.isCapturing,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Optional observation',
                hintText: 'Idle duration, charging state, or anything unusual',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _controller.isCapturing ? null : _controller.capture,
              icon: _controller.isCapturing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_chart),
              label: Text(
                _controller.isCapturing ? 'Capturing…' : 'Capture snapshot',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard(
    BuildContext context,
    MemorySnapshot snapshot,
    int number,
  ) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: number == _controller.snapshots.length,
        title: Text('$number. ${snapshot.stage}'),
        subtitle: Text(
          '${snapshot.manufacturer} ${snapshot.model} · '
          '${_formatTimestamp(snapshot.capturedAt)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (snapshot.note.isNotEmpty) ...[
            SelectableText('Note: ${snapshot.note}'),
            const SizedBox(height: 12),
          ],
          _metricRow('Kernel-accessible total', snapshot.totalMemoryBytes),
          _metricRow('Available memory', snapshot.availableMemoryBytes),
          if (snapshot.freeMemoryBytes != null)
            _metricRow('Unused/free memory', snapshot.freeMemoryBytes!),
          _metricRow(
            'Estimated used (total − available)',
            snapshot.estimatedUsedMemoryBytes,
          ),
          if (snapshot.advertisedMemoryBytes != null)
            _metricRow('Advertised memory', snapshot.advertisedMemoryBytes!),
          const Divider(height: 24),
          _metricKibRow('Nano Lab total PSS', snapshot.totalPssKib),
          if (snapshot.totalRssKib != null)
            _metricKibRow('Nano Lab total RSS', snapshot.totalRssKib!),
          _metricKibRow(
            'Nano Lab private dirty',
            snapshot.totalPrivateDirtyKib,
          ),
          _metricRow(
            'Native heap allocated',
            snapshot.nativeHeapAllocatedBytes,
          ),
          const Divider(height: 24),
          Text(
            'Battery: ${snapshot.batteryPercent?.toStringAsFixed(0) ?? '—'}% · '
            '${snapshot.batteryTemperatureCelsius?.toStringAsFixed(1) ?? '—'} °C',
          ),
          Text('Thermal status: ${_thermalStatus(snapshot.thermalStatus)}'),
          Text(
            'Android ${snapshot.androidVersion} (SDK ${snapshot.sdkLevel}) · '
            'PID ${snapshot.processId}',
          ),
          const SizedBox(height: 10),
          const Text(
            'Available and estimated-used memory describe the whole system. '
            'Changes cannot be attributed to AICore without matching ADB data.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAdbCard(BuildContext context) {
    const commands =
        'adb devices\n'
        'adb shell dumpsys meminfo\n'
        'adb shell dumpsys meminfo com.mycarejournals.nano_lab\n'
        'adb shell ps -A | findstr /i aicore\n'
        'adb shell pm list packages | findstr /i aicore';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Read-only ADB companion measurements',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Run these from PowerShell at every matching stage. Discover '
              'the actual AICore package or process first; do not assume its '
              'name and do not disable, clear, or force-stop it yet.',
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SelectableText(
                commands,
                style: TextStyle(fontFamily: 'monospace', height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'After discovering a candidate package or PID, capture it with '
              'adb shell dumpsys meminfo <package-or-pid>. Treat PSS as a '
              'process snapshot—not proof of permanently reserved RAM.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, int bytes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text('$label: ${_formatBytes(bytes)}'),
    );
  }

  Widget _metricKibRow(String label, int kib) {
    return _metricRow(label, kib * 1024);
  }

  String _formatBytes(int bytes) {
    const gib = 1024 * 1024 * 1024;
    const mib = 1024 * 1024;
    if (bytes.abs() >= gib) {
      return '${(bytes / gib).toStringAsFixed(2)} GiB';
    }
    return '${(bytes / mib).toStringAsFixed(1)} MiB';
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} '
        '$hour:$minute $period';
  }

  String _thermalStatus(int? status) {
    switch (status) {
      case 0:
        return 'None';
      case 1:
        return 'Light';
      case 2:
        return 'Moderate';
      case 3:
        return 'Severe';
      case 4:
        return 'Critical';
      case 5:
        return 'Emergency';
      case 6:
        return 'Shutdown';
      default:
        return 'Unavailable';
    }
  }
}
