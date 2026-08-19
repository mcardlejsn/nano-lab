import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../models/memory_snapshot.dart';
import '../../services/nano_native_service.dart';

class MemoryExperimentController extends ChangeNotifier {
  MemoryExperimentController({required this._nativeService});

  static const stages = <String>[
    'App opened; ML Kit clients constructed; no status check',
    'After Nano/AICore availability check',
    'After first identical prompt',
    'After five identical prompts',
    'After idle period',
    'Custom observation',
  ];

  final NanoNativeService _nativeService;
  final TextEditingController noteController = TextEditingController();
  final List<MemorySnapshot> snapshots = <MemorySnapshot>[];

  String selectedStage = stages.first;
  bool isCapturing = false;
  String? error;

  void selectStage(String stage) {
    selectedStage = stage;
    notifyListeners();
  }

  Future<void> capture() async {
    isCapturing = true;
    error = null;
    notifyListeners();

    try {
      final result = await _nativeService.getMemorySnapshot();
      if (result == null) {
        error = 'Kotlin returned no memory snapshot.';
        return;
      }

      snapshots.add(
        MemorySnapshot.fromNative(
          stage: selectedStage,
          note: noteController.text.trim(),
          data: result,
        ),
      );
      noteController.clear();
    } on PlatformException catch (platformError) {
      error =
          '${platformError.message ?? 'Memory snapshot capture failed.'}\n'
          'Platform error: ${platformError.code}';
    } catch (unexpectedError) {
      error = 'Unexpected memory snapshot error: $unexpectedError';
    } finally {
      isCapturing = false;
      notifyListeners();
    }
  }

  void clear() {
    snapshots.clear();
    error = null;
    notifyListeners();
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'experiment': 'Nano Lab Memory Experiment',
      'measurementBoundary': <String, dynamic>{
        'inAppDirectMeasurements': <String>[
          'Android system memory summary',
          'Nano Lab process memory',
          'battery and thermal context',
        ],
        'notMeasuredInApp': <String>[
          'AICore process memory',
          'other app process memory',
          'GPU or accelerator allocations not attributed by Android APIs',
        ],
      },
      'snapshots': snapshots.map((snapshot) => snapshot.toJson()).toList(),
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
