import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'groq_transcription_service.dart';
import 'speech_text_normalizer.dart';

/// Recording state enumeration
enum VoiceRecordingState {
  idle,
  recording,
  processing,
  transcribing,
  completed,
  error,
}

/// Exception for voice recording errors
class VoiceRecordingException implements Exception {
  final String message;
  final String? errorCode;

  VoiceRecordingException({
    required this.message,
    this.errorCode,
  });

  @override
  String toString() => 'VoiceRecordingException: $message (code: $errorCode)';
}

/// Singleton service managing voice recording and transcription
class VoiceRecordingService {
  static const String _debugTag = '[VoiceRecordingService]';
  static final VoiceRecordingService _instance = VoiceRecordingService._internal();

  factory VoiceRecordingService() {
    return _instance;
  }

  VoiceRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final GroqTranscriptionService _groqService = GroqTranscriptionService();
  
  bool _isRecording = false;
  String? _activeFieldId;
  String? _transcribingFieldId;
  String? _currentRecordingPath;
  final List<Function(VoiceRecordingState)> _stateListeners = [];

  static const Duration defaultAmplitudeInterval = Duration(milliseconds: 150);

  /// The field currently owning the microphone session.
  String? get activeFieldId => _activeFieldId;

  /// Notifies widgets when the active field changes so inactive widgets can reset.
  final ValueNotifier<String?> activeFieldIdNotifier = ValueNotifier<String?>(null);

  /// Start recording audio
  Future<String> startRecording({required String fieldId}) async {
    if (_isRecording) {
      await cancelRecording();
    }

    try {
      _activeFieldId = fieldId;
      activeFieldIdNotifier.value = fieldId;

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_recording_$timestamp.wav';

      debugPrint('$_debugTag Starting recording to: $_currentRecordingPath');
      _notifyStateListeners(VoiceRecordingState.recording);

      // Start recording
        await _recorder.start(
          RecordConfig(encoder: AudioEncoder.wav),
          path: _currentRecordingPath!,
        );

      _isRecording = true;
      debugPrint('$_debugTag Recording started');
      return _currentRecordingPath!;
    } catch (e) {
      debugPrint('$_debugTag Error starting recording: $e');
      _notifyStateListeners(VoiceRecordingState.error);
      throw VoiceRecordingException(
        message: 'Failed to start recording: ${e.toString()}',
        errorCode: 'START_FAILED',
      );
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      throw VoiceRecordingException(
        message: 'No recording in progress',
        errorCode: 'NOT_RECORDING',
      );
    }

    try {
      debugPrint('$_debugTag Stopping recording');
      final path = await _recorder.stop();
      
      _isRecording = false;
      _notifyStateListeners(VoiceRecordingState.processing);

      debugPrint('$_debugTag Recording stopped: $path');
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('$_debugTag Error stopping recording: $e');
      _isRecording = false;
      _notifyStateListeners(VoiceRecordingState.error);
      throw VoiceRecordingException(
        message: 'Failed to stop recording: ${e.toString()}',
        errorCode: 'STOP_FAILED',
      );
    }
  }

  /// Transcribe audio file using Groq Whisper API
  Future<String> transcribeAudio(
    String audioFilePath, {
    String? fieldId,
  }) async {
    final requestFieldId = fieldId ?? _activeFieldId;

    if (requestFieldId == null) {
      throw VoiceRecordingException(
        message: 'Transcription session has no active field',
        errorCode: 'SESSION_SUPERSEDED',
      );
    }

    if (fieldId != null && fieldId != _activeFieldId) {
      throw VoiceRecordingException(
        message: 'This recording session was superseded by another field',
        errorCode: 'SESSION_SUPERSEDED',
      );
    }

    _transcribingFieldId = requestFieldId;
    try {
      _notifyStateListeners(VoiceRecordingState.transcribing);
      
      debugPrint('$_debugTag Sending to Groq Whisper API: $audioFilePath');
      final response = await _groqService.transcribeAudio(audioFilePath);

      if (_transcribingFieldId != requestFieldId) {
        throw VoiceRecordingException(
          message: 'This transcription session was superseded',
          errorCode: 'SESSION_SUPERSEDED',
        );
      }
      
      final text = cleanTranscription(response.text);
      if (text.isEmpty) {
        throw VoiceRecordingException(
          message: 'No speech detected in audio',
          errorCode: 'NO_SPEECH_DETECTED',
        );
      }

      debugPrint('$_debugTag Transcription successful: "$text"');
      _notifyStateListeners(VoiceRecordingState.completed);
      return text;
    } on GroqWhisperException catch (e) {
      debugPrint('$_debugTag Groq error: ${e.message}');
      _notifyStateListeners(VoiceRecordingState.error);
      throw VoiceRecordingException(
        message: e.message,
        errorCode: 'GROQ_ERROR_${e.errorCode}',
      );
    } catch (e) {
      debugPrint('$_debugTag Transcription error: $e');
      _notifyStateListeners(VoiceRecordingState.error);
      throw VoiceRecordingException(
        message: 'Transcription failed: ${e.toString()}',
        errorCode: 'TRANSCRIPTION_FAILED',
      );
    } finally {
      if (_transcribingFieldId == requestFieldId) {
        _transcribingFieldId = null;
      }
    }
  }

  /// Stream audio amplitude in decibels while recording.
  /// Typical values are around -160 (silence) to 0 (very loud).
  Stream<double> amplitudeStream({Duration interval = defaultAmplitudeInterval}) {
    return _recorder.onAmplitudeChanged(interval).map((amplitude) => amplitude.current);
  }

  /// Normalize and remove repeated word/phrase loops in transcribed text.
  String cleanTranscription(String input) {
    return SpeechTextNormalizer.cleanTranscription(input);
  }

  /// Record and transcribe audio in one operation
  Future<String> recordAndTranscribe({
    String? fieldId,
    Duration? maxDuration,
  }) async {
    String? recordingPath;
    try {
      // Start recording
      recordingPath = await startRecording(fieldId: fieldId ?? 'record-and-transcribe');

      // Wait for recording (or max duration)
      if (maxDuration != null) {
        await Future.delayed(maxDuration);
        if (_isRecording) {
          await stopRecording();
        }
      }

      // Stop recording (if not already stopped)
      if (_isRecording) {
        recordingPath = await stopRecording();
      }

      if (recordingPath == null || recordingPath.isEmpty) {
        throw VoiceRecordingException(
          message: 'No recording path available',
          errorCode: 'NO_RECORDING_PATH',
        );
      }

      // Transcribe
      final transcribedText = await transcribeAudio(
        recordingPath,
        fieldId: fieldId ?? _activeFieldId,
      );

      // Clean up
      await _deleteFile(recordingPath);

      _notifyStateListeners(VoiceRecordingState.idle);
      if (fieldId == null || fieldId == _activeFieldId) {
        _activeFieldId = null;
        activeFieldIdNotifier.value = null;
      }
      return transcribedText;
    } catch (e) {
      // Clean up on error
      if (recordingPath != null) {
        await _deleteFile(recordingPath);
      }
      if (fieldId == null || fieldId == _activeFieldId) {
        _activeFieldId = null;
        activeFieldIdNotifier.value = null;
      }
      rethrow;
    }
  }

  /// Cancel current recording without transcription
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      if (_currentRecordingPath != null) {
        await _deleteFile(_currentRecordingPath!);
        _currentRecordingPath = null;
      }

      _activeFieldId = null;
      activeFieldIdNotifier.value = null;

      _notifyStateListeners(VoiceRecordingState.idle);
      debugPrint('$_debugTag Recording cancelled');
    } catch (e) {
      debugPrint('$_debugTag Error cancelling recording: $e');
    }
  }

  /// Delete audio file
  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('$_debugTag Deleted file: $filePath');
      }
    } catch (e) {
      debugPrint('$_debugTag Error deleting file: $e');
    }
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Listen to recording state changes
  void addStateListener(Function(VoiceRecordingState) listener) {
    _stateListeners.add(listener);
  }

  /// Remove state listener
  void removeStateListener(Function(VoiceRecordingState) listener) {
    _stateListeners.remove(listener);
  }

  /// Notify all state listeners
  void _notifyStateListeners(VoiceRecordingState state) {
    for (final listener in _stateListeners) {
      listener(state);
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _groqService.dispose();
    activeFieldIdNotifier.dispose();
    _stateListeners.clear();
    debugPrint('$_debugTag Disposed');
  }
}
