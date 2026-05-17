import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/numeric_voice_validation.dart';
import '../services/microphone_permission_service.dart';
import '../services/speech_text_normalizer.dart';
import '../services/voice_recording_service.dart';

/// Voice input microphone button with Groq Whisper transcription.
///
/// Each instance is bound to a unique field ID so only the tapped field shows
/// recording/transcribing state and only one field can own the active session.
class VoiceInputMicButton extends StatefulWidget {
  final TextEditingController controller;
  final String fieldLabel;
  final String? fieldId;
  final FocusNode? nextFocusNode;
  final VoiceInputMode voiceInputMode;
  final void Function(String fieldId, String message)? onInvalidVoiceInput;

  const VoiceInputMicButton({
    super.key,
    required this.controller,
    required this.fieldLabel,
    this.fieldId,
    this.nextFocusNode,
    this.voiceInputMode = VoiceInputMode.text,
    this.onInvalidVoiceInput,
  });

  @override
  State<VoiceInputMicButton> createState() => _VoiceInputMicButtonState();
}

class _VoiceInputMicButtonState extends State<VoiceInputMicButton> {
  static const String _debugTag = '[VoiceInputMicButton]';
  static const Duration _silenceTimeout = Duration(seconds: 2);
  static const Duration _maxRecordingDuration = Duration(seconds: 6);
  static const double _speechThresholdDb = -42;

  late final VoiceRecordingService _voiceService;
  late final MicrophonePermissionService _permissionService;

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _recordingFailed = false;
  bool _isStoppingRecording = false;
  bool _hasSentTranscription = false;
  bool _speechDetected = false;

  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;

  String get _resolvedFieldId => widget.fieldId ?? widget.fieldLabel;
  bool get _isThisFieldActive => _voiceService.activeFieldId == _resolvedFieldId;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _permissionService = MicrophonePermissionService();
    _voiceService.addStateListener(_handleRecordingStateChange);
    _voiceService.activeFieldIdNotifier.addListener(_handleActiveFieldChanged);
  }

  @override
  void dispose() {
    _cancelRecordingMonitors();
    _voiceService.removeStateListener(_handleRecordingStateChange);
    _voiceService.activeFieldIdNotifier.removeListener(_handleActiveFieldChanged);
    super.dispose();
  }

  void _handleActiveFieldChanged() {
    if (!mounted) return;

    if (!_isThisFieldActive && (_isRecording || _isTranscribing || _isStoppingRecording)) {
      setState(() {
        _isRecording = false;
        _isTranscribing = false;
        _isStoppingRecording = false;
        _hasSentTranscription = false;
        _speechDetected = false;
        _recordingFailed = false;
      });
      _cancelRecordingMonitors();
    }
  }

  void _handleRecordingStateChange(VoiceRecordingState state) {
    if (!mounted) return;
    if (!_isThisFieldActive && state != VoiceRecordingState.idle) return;

    switch (state) {
      case VoiceRecordingState.recording:
        setState(() {
          _isRecording = true;
          _isTranscribing = false;
          _recordingFailed = false;
        });
        break;
      case VoiceRecordingState.processing:
      case VoiceRecordingState.transcribing:
        setState(() {
          _isRecording = false;
          _isTranscribing = true;
        });
        break;
      case VoiceRecordingState.completed:
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
          _isStoppingRecording = false;
        });
        break;
      case VoiceRecordingState.error:
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
          _recordingFailed = true;
          _isStoppingRecording = false;
        });
        break;
      case VoiceRecordingState.idle:
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
          _isStoppingRecording = false;
        });
        break;
    }
  }

  Future<void> _onMicrophoneTap() async {
    HapticFeedback.lightImpact();

    if (_isStoppingRecording || _isTranscribing) return;

    if (_isRecording) {
      await _stopRecordingAndTranscribe(trigger: 'manual-stop');
      return;
    }

    final hasPermission = await _permissionService.isPermissionGranted();
    if (!hasPermission) {
      final status = await _permissionService.requestPermission();
      if (status != MicrophonePermissionStatus.granted) {
        _showPermissionDialog(status);
        return;
      }
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      _cancelRecordingMonitors();
      _hasSentTranscription = false;
      _speechDetected = false;
      _recordingFailed = false;

      debugPrint('$_debugTag Starting voice recording for $_resolvedFieldId');
      await _voiceService.startRecording(fieldId: _resolvedFieldId);

      _startMaxDurationTimer();
      _startAmplitudeMonitor();
    } catch (e) {
      debugPrint('$_debugTag Error starting recording: $e');
      if (mounted) {
        setState(() {
          _recordingFailed = true;
        });
      }
      _showErrorDialog('Failed to start recording', e.toString());
    }
  }

  Future<void> _stopRecordingAndTranscribe({required String trigger}) async {
    if (_isStoppingRecording || _hasSentTranscription) return;

    _isStoppingRecording = true;
    _cancelRecordingMonitors();

    try {
      debugPrint('$_debugTag Stopping recording ($trigger) for $_resolvedFieldId');

      final audioPath = await _voiceService.stopRecording();
      if (audioPath == null || audioPath.isEmpty) {
        throw Exception('No recording path available');
      }

      _hasSentTranscription = true;
      final transcribedText = await _voiceService.transcribeAudio(
        audioPath,
        fieldId: _resolvedFieldId,
      );

      final cleanedText = widget.voiceInputMode == VoiceInputMode.numeric
          ? SpeechTextNormalizer.cleanNumericTranscription(transcribedText)
          : SpeechTextNormalizer.cleanTranscription(transcribedText);
      final normalizedText = SpeechTextNormalizer.normalize(
        transcribedText,
        mode: widget.voiceInputMode,
      );
      final isValid = widget.voiceInputMode != VoiceInputMode.numeric ||
          NumericVoiceValidator.isValid(normalizedText);

      debugPrint('$_debugTag Raw transcription: "$transcribedText"');
      debugPrint('$_debugTag Cleaned transcription: "$cleanedText"');
      debugPrint('$_debugTag Normalized transcription: "$normalizedText"');
      debugPrint('$_debugTag Validation result: $isValid');

      if (widget.voiceInputMode == VoiceInputMode.numeric && !isValid) {
        _handleInvalidNumericInput();
        return;
      }

      if (mounted) {
        widget.controller.value = TextEditingValue(
          text: normalizedText,
          selection: TextSelection.collapsed(offset: normalizedText.length),
        );
        widget.nextFocusNode?.requestFocus();
        FocusScope.of(context).unfocus();
      }

      debugPrint('$_debugTag Transcription successful: "$transcribedText" -> "$normalizedText"');
    } on VoiceRecordingException catch (e) {
      debugPrint('$_debugTag Recording error: ${e.message}');
      if (mounted) {
        setState(() {
          _recordingFailed = true;
        });
      }
      _showErrorDialog(
        'Voice transcription failed',
        _getUserFriendlyErrorMessage(e.errorCode),
      );
    } catch (e) {
      debugPrint('$_debugTag Unexpected error: $e');
      if (mounted) {
        setState(() {
          _recordingFailed = true;
        });
      }
      _showErrorDialog('Voice transcription failed', e.toString());
    } finally {
      _isStoppingRecording = false;
    }
  }

  void _handleInvalidNumericInput() {
    if (!mounted) return;

    final message = NumericVoiceValidator.invalidVoiceMessage;
    widget.onInvalidVoiceInput?.call(_resolvedFieldId, message);

    if (widget.onInvalidVoiceInput == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numeric input required'),
        ),
      );
    }

    debugPrint('$_debugTag Rejected non-numeric transcription for $_resolvedFieldId');
  }

  void _startAmplitudeMonitor() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _voiceService
        .amplitudeStream(interval: VoiceRecordingService.defaultAmplitudeInterval)
        .listen((db) {
      if (!_isRecording || _isStoppingRecording || !_isThisFieldActive) return;

      if (db > _speechThresholdDb) {
        _speechDetected = true;
        _silenceTimer?.cancel();
        _silenceTimer = null;
        return;
      }

      if (_speechDetected && _silenceTimer == null) {
        _silenceTimer = Timer(_silenceTimeout, () {
          _stopRecordingAndTranscribe(trigger: 'silence-timeout');
        });
      }
    }, onError: (Object error) {
      debugPrint('$_debugTag Amplitude monitor error: $error');
    });
  }

  void _startMaxDurationTimer() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(_maxRecordingDuration, () {
      _stopRecordingAndTranscribe(trigger: 'max-duration');
    });
  }

  void _cancelRecordingMonitors() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
  }

  String _getUserFriendlyErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'NO_SPEECH_DETECTED':
        return 'No speech detected. Please speak clearly and try again.';
      case 'PERMISSION_DENIED':
        return 'Microphone permission is required for voice input.';
      case 'TIMEOUT':
        return 'Connection timeout. Please check your internet connection.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your internet connection.';
      case 'GROQ_ERROR_MISSING_API_KEY':
        return 'Voice transcription is not configured. Please contact support.';
      case 'GROQ_ERROR_BAD_RESPONSE':
        return 'Transcription service error. Please try again.';
      default:
        return 'Voice transcription failed. Please try again.';
    }
  }

  void _showPermissionDialog(MicrophonePermissionStatus status) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: Text(_permissionService.getDetailedExplanation(status)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (_permissionService.canRequestPermission(status))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _permissionService.requestPermission();
              },
              child: Text(_permissionService.getActionButtonLabel(status)),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: Text(_permissionService.getActionButtonLabel(status)),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startRecording();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneContent() {
    if (_isTranscribing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
        ),
      );
    }

    if (_isRecording) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1.12),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Icon(
          Icons.mic,
          size: 18,
          color: Colors.red.shade600,
        ),
      );
    }

    if (_recordingFailed) {
      return Icon(Icons.mic_off, size: 18, color: Colors.red.shade600);
    }

    return Icon(Icons.mic_none, size: 18, color: const Color(0xFF6B7280));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: _isTranscribing || _isStoppingRecording ? null : _onMicrophoneTap,
        radius: 22,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isTranscribing
                ? const Color(0xFFF0F4FF)
                : (_isRecording
                    ? const Color(0xFFFFEEF0)
                    : (_recordingFailed ? const Color(0xFFFEE2E2) : const Color(0xFFF9FAFB))),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isRecording
                  ? Colors.red.shade200
                  : (_isTranscribing ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB)),
              width: 1,
            ),
            boxShadow: _isRecording
                ? [
                    BoxShadow(
                      color: Colors.red.shade200.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: _buildMicrophoneContent(),
        ),
      ),
    );
  }
}
