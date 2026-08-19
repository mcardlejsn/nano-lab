class MemorySnapshot {
  const MemorySnapshot({
    required this.stage,
    required this.note,
    required this.capturedAt,
    required this.elapsedRealtimeMilliseconds,
    required this.processId,
    required this.manufacturer,
    required this.model,
    required this.device,
    required this.hardware,
    required this.androidVersion,
    required this.sdkLevel,
    required this.buildFingerprint,
    required this.advertisedMemoryBytes,
    required this.totalMemoryBytes,
    required this.availableMemoryBytes,
    required this.freeMemoryBytes,
    required this.lowMemoryThresholdBytes,
    required this.lowMemory,
    required this.totalPssKib,
    required this.totalRssKib,
    required this.totalPrivateDirtyKib,
    required this.totalPrivateCleanKib,
    required this.totalSharedDirtyKib,
    required this.totalSharedCleanKib,
    required this.totalSwappablePssKib,
    required this.nativeHeapAllocatedBytes,
    required this.nativeHeapSizeBytes,
    required this.processImportance,
    required this.lastTrimLevel,
    required this.memoryStatsKib,
    required this.batteryPercent,
    required this.batteryTemperatureCelsius,
    required this.thermalStatus,
  });

  factory MemorySnapshot.fromNative({
    required String stage,
    required String note,
    required Map<String, dynamic> data,
  }) {
    final system = _stringMap(data['system']);
    final process = _stringMap(data['process']);
    final environment = _stringMap(data['environment']);
    final device = _stringMap(data['device']);
    final rawMemoryStats = _stringMap(process['memoryStatsKib']);

    return MemorySnapshot(
      stage: stage,
      note: note,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        _integer(data['capturedAtEpochMilliseconds']) ?? 0,
      ),
      elapsedRealtimeMilliseconds:
          _integer(data['elapsedRealtimeMilliseconds']) ?? 0,
      processId: _integer(data['pid']) ?? 0,
      manufacturer: device['manufacturer']?.toString() ?? 'unknown',
      model: device['model']?.toString() ?? 'unknown',
      device: device['device']?.toString() ?? 'unknown',
      hardware: device['hardware']?.toString() ?? 'unknown',
      androidVersion: device['androidVersion']?.toString() ?? 'unknown',
      sdkLevel: _integer(device['sdkLevel']) ?? 0,
      buildFingerprint: device['buildFingerprint']?.toString() ?? 'unknown',
      advertisedMemoryBytes: _integer(system['advertisedMemoryBytes']),
      totalMemoryBytes: _integer(system['totalMemoryBytes']) ?? 0,
      availableMemoryBytes: _integer(system['availableMemoryBytes']) ?? 0,
      freeMemoryBytes: _integer(system['freeMemoryBytes']),
      lowMemoryThresholdBytes: _integer(system['lowMemoryThresholdBytes']) ?? 0,
      lowMemory: system['lowMemory'] == true,
      totalPssKib: _integer(process['totalPssKib']) ?? 0,
      totalRssKib: _integer(process['totalRssKib']),
      totalPrivateDirtyKib: _integer(process['totalPrivateDirtyKib']) ?? 0,
      totalPrivateCleanKib: _integer(process['totalPrivateCleanKib']) ?? 0,
      totalSharedDirtyKib: _integer(process['totalSharedDirtyKib']) ?? 0,
      totalSharedCleanKib: _integer(process['totalSharedCleanKib']) ?? 0,
      totalSwappablePssKib: _integer(process['totalSwappablePssKib']) ?? 0,
      nativeHeapAllocatedBytes:
          _integer(process['nativeHeapAllocatedBytes']) ?? 0,
      nativeHeapSizeBytes: _integer(process['nativeHeapSizeBytes']) ?? 0,
      processImportance: _integer(process['importance']) ?? 0,
      lastTrimLevel: _integer(process['lastTrimLevel']) ?? 0,
      memoryStatsKib: rawMemoryStats.map(
        (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
      ),
      batteryPercent: _number(environment['batteryPercent']),
      batteryTemperatureCelsius: _number(
        environment['batteryTemperatureCelsius'],
      ),
      thermalStatus: _integer(environment['thermalStatus']),
    );
  }

  final String stage;
  final String note;
  final DateTime capturedAt;
  final int elapsedRealtimeMilliseconds;
  final int processId;
  final String manufacturer;
  final String model;
  final String device;
  final String hardware;
  final String androidVersion;
  final int sdkLevel;
  final String buildFingerprint;

  final int? advertisedMemoryBytes;
  final int totalMemoryBytes;
  final int availableMemoryBytes;
  final int? freeMemoryBytes;
  final int lowMemoryThresholdBytes;
  final bool lowMemory;

  final int totalPssKib;
  final int? totalRssKib;
  final int totalPrivateDirtyKib;
  final int totalPrivateCleanKib;
  final int totalSharedDirtyKib;
  final int totalSharedCleanKib;
  final int totalSwappablePssKib;
  final int nativeHeapAllocatedBytes;
  final int nativeHeapSizeBytes;
  final int processImportance;
  final int lastTrimLevel;
  final Map<String, int> memoryStatsKib;

  final double? batteryPercent;
  final double? batteryTemperatureCelsius;
  final int? thermalStatus;

  int get estimatedUsedMemoryBytes => totalMemoryBytes - availableMemoryBytes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stage': stage,
      'note': note,
      'capturedAt': capturedAt.toIso8601String(),
      'elapsedRealtimeMilliseconds': elapsedRealtimeMilliseconds,
      'processId': processId,
      'device': <String, dynamic>{
        'manufacturer': manufacturer,
        'model': model,
        'device': device,
        'hardware': hardware,
        'androidVersion': androidVersion,
        'sdkLevel': sdkLevel,
        'buildFingerprint': buildFingerprint,
      },
      'system': <String, dynamic>{
        'advertisedMemoryBytes': advertisedMemoryBytes,
        'totalMemoryBytes': totalMemoryBytes,
        'availableMemoryBytes': availableMemoryBytes,
        'freeMemoryBytes': freeMemoryBytes,
        'estimatedUsedMemoryBytes': estimatedUsedMemoryBytes,
        'lowMemoryThresholdBytes': lowMemoryThresholdBytes,
        'lowMemory': lowMemory,
      },
      'nanoLabProcess': <String, dynamic>{
        'totalPssKib': totalPssKib,
        'totalRssKib': totalRssKib,
        'totalPrivateDirtyKib': totalPrivateDirtyKib,
        'totalPrivateCleanKib': totalPrivateCleanKib,
        'totalSharedDirtyKib': totalSharedDirtyKib,
        'totalSharedCleanKib': totalSharedCleanKib,
        'totalSwappablePssKib': totalSwappablePssKib,
        'nativeHeapAllocatedBytes': nativeHeapAllocatedBytes,
        'nativeHeapSizeBytes': nativeHeapSizeBytes,
        'importance': processImportance,
        'lastTrimLevel': lastTrimLevel,
        'memoryStatsKib': memoryStatsKib,
      },
      'environment': <String, dynamic>{
        'batteryPercent': batteryPercent,
        'batteryTemperatureCelsius': batteryTemperatureCelsius,
        'thermalStatus': thermalStatus,
      },
    };
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  static int? _integer(dynamic value) => value is int ? value : null;

  static double? _number(dynamic value) =>
      value is num ? value.toDouble() : null;
}
