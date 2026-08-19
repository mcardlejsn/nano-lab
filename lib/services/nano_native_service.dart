import 'package:flutter/services.dart';

class NanoNativeService {
  const NanoNativeService();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.mycarejournals.nano_lab/native',
  );

  static const EventChannel _promptDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/download_events',
  );

  static const EventChannel _promptChannel = EventChannel(
    'com.mycarejournals.nano_lab/prompt_events',
  );

  static const EventChannel _summarizationDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/summarization_download_events',
  );

  static const EventChannel _rewritingDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/rewriting_download_events',
  );

  static const EventChannel _proofreadingDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/proofreading_download_events',
  );

  static const EventChannel _imageDescriptionDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/image_description_download_events',
  );

  static const EventChannel _speechRecognitionDownloadChannel = EventChannel(
    'com.mycarejournals.nano_lab/speech_recognition_download_events',
  );

  static const EventChannel _speechRecognitionChannel = EventChannel(
    'com.mycarejournals.nano_lab/speech_recognition_events',
  );

  Stream<dynamic> get promptDownloadEvents =>
      _promptDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get promptEvents => _promptChannel.receiveBroadcastStream();

  Stream<dynamic> get summarizationDownloadEvents =>
      _summarizationDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get rewritingDownloadEvents =>
      _rewritingDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get proofreadingDownloadEvents =>
      _proofreadingDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get imageDescriptionDownloadEvents =>
      _imageDescriptionDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get speechRecognitionDownloadEvents =>
      _speechRecognitionDownloadChannel.receiveBroadcastStream();

  Stream<dynamic> get speechRecognitionEvents =>
      _speechRecognitionChannel.receiveBroadcastStream();

  Future<Map<String, dynamic>?> getPromptStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>('getPromptStatus');
  }

  Future<Map<String, dynamic>?> getDeviceInfo() {
    return _methodChannel.invokeMapMethod<String, dynamic>('getDeviceInfo');
  }

  Future<Map<String, dynamic>?> getMemorySnapshot() {
    return _methodChannel.invokeMapMethod<String, dynamic>('getMemorySnapshot');
  }

  Future<Map<String, dynamic>?> setModelReleaseStage(String releaseStage) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'setModelReleaseStage',
      <String, dynamic>{'modelReleaseStage': releaseStage},
    );
  }

  Future<Map<String, dynamic>?> getSystemInstructionStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getSystemInstructionStatus',
    );
  }

  Future<void> startPromptDownload() async {
    await _methodChannel.invokeMethod<dynamic>('startPromptDownload');
  }

  Future<Map<String, dynamic>?> getSummarizationStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getSummarizationStatus',
    );
  }

  Future<void> startSummarizationDownload() async {
    await _methodChannel.invokeMethod<dynamic>('startSummarizationDownload');
  }

  Future<Map<String, dynamic>?> runSummarization(String text) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'runSummarization',
      <String, dynamic>{'text': text},
    );
  }

  Future<Map<String, dynamic>?> getRewritingStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getRewritingStatus',
    );
  }

  Future<void> startRewritingDownload() async {
    await _methodChannel.invokeMethod<dynamic>('startRewritingDownload');
  }

  Future<Map<String, dynamic>?> runRewriting(String text) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'runRewriting',
      <String, dynamic>{'text': text},
    );
  }

  Future<Map<String, dynamic>?> getProofreadingStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getProofreadingStatus',
    );
  }

  Future<void> startProofreadingDownload() async {
    await _methodChannel.invokeMethod<dynamic>('startProofreadingDownload');
  }

  Future<Map<String, dynamic>?> runProofreading(String text) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'runProofreading',
      <String, dynamic>{'text': text},
    );
  }

  Future<Map<String, dynamic>?> getImageDescriptionTestImage(String imageId) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getImageDescriptionTestImage',
      <String, dynamic>{'imageId': imageId},
    );
  }

  Future<Map<String, dynamic>?> getImageDescriptionStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getImageDescriptionStatus',
    );
  }

  Future<void> startImageDescriptionDownload() async {
    await _methodChannel.invokeMethod<dynamic>('startImageDescriptionDownload');
  }

  Future<Map<String, dynamic>?> runImageDescription(String imageId) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'runImageDescription',
      <String, dynamic>{'imageId': imageId},
    );
  }

  Future<Map<String, dynamic>?> getSpeechRecognitionStatus() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getSpeechRecognitionStatus',
    );
  }

  Future<void> startSpeechRecognitionDownload() async {
    await _methodChannel.invokeMethod<dynamic>(
      'startSpeechRecognitionDownload',
    );
  }

  Future<Map<String, dynamic>?> requestSpeechRecognitionPermission() {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'requestSpeechRecognitionPermission',
    );
  }

  Future<void> startSpeechRecognition() async {
    await _methodChannel.invokeMethod<dynamic>('startSpeechRecognition');
  }

  Future<void> stopSpeechRecognition() async {
    await _methodChannel.invokeMethod<dynamic>('stopSpeechRecognition');
  }

  Future<Map<String, dynamic>?> getTokenInfo(Map<String, dynamic> arguments) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'getTokenInfo',
      arguments,
    );
  }

  Future<Map<String, dynamic>?> runPrompt(Map<String, dynamic> arguments) {
    return _methodChannel.invokeMapMethod<String, dynamic>(
      'runPrompt',
      arguments,
    );
  }
}
