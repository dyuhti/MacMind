import '../services/speech_text_normalizer.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/numeric_voice_validation.dart';
import '../services/microphone_permission_service.dart';
import '../services/voice_recording_service.dart';

/// Pressure input field with Groq-backed voice input.
class PressureInputField extends StatefulWidget {
  final Function(String) onPressureChanged;
  final String? initialValue;
  final String fieldId;

  const PressureInputField({
    super.key,
    required this.onPressureChanged,
    this.initialValue,
    this.fieldId = 'pressure-input',
  });

  @override
  State<PressureInputField> createState() => _PressureInputFieldState();
}

class _PressureInputFieldState extends State<PressureInputField> {
  static const String _debugTag = '[PressureInputField]';
  static const Duration _silenceTimeout = Duration(seconds: 2);
  static const Duration _maxRecordingDuration = Duration(seconds: 6);
  static const double _speechThresholdDb = -42;

  final TextEditingController _controller = TextEditingController();
  late final VoiceRecordingService _voiceService;
  late final MicrophonePermissionService _permissionService;

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _voiceFailed = false;
  String? _lastError;
  bool _isStoppingRecording = false;
  bool _hasSentTranscription = false;
  bool _speechDetected = false;

  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;

  String get _resolvedFieldId => widget.fieldId;
  bool get _isThisFieldActive => _voiceService.activeFieldId == _resolvedFieldId;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _voiceService = VoiceRecordingService();
    _permissionService = MicrophonePermissionService();
    _voiceService.addStateListener(_handleVoiceStateChange);
    _voiceService.activeFieldIdNotifier.addListener(_handleActiveFieldChanged);
  }

  @override
  void dispose() {
    _cancelRecordingMonitors();
    _voiceService.removeStateListener(_handleVoiceStateChange);
    _voiceService.activeFieldIdNotifier.removeListener(_handleActiveFieldChanged);
    _controller.dispose();
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
        _voiceFailed = false;
        _lastError = null;
      });
      _cancelRecordingMonitors();
    }
  }

  void _handleVoiceStateChange(VoiceRecordingState state) {
    if (!mounted) return;

    if (!_isThisFieldActive) {
      return;
    }

    switch (state) {
      case VoiceRecordingState.recording:
        setState(() {
          _isRecording = true;
          _isTranscribing = false;
          _voiceFailed = false;
          _lastError = null;
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
          _voiceFailed = false;
          _lastError = null;
        });
        break;
      case VoiceRecordingState.error:
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
          _voiceFailed = true;
        });
        break;
      case VoiceRecordingState.idle:
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
        });
        break;
    }
  }

  Future<void> _handleMicTap() async {
    HapticFeedback.lightImpact();

    if (_isStoppingRecording) {
      return;
    }

    if (_isRecording) {
      await _stopAndTranscribe(trigger: 'manual-stop');
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

      debugPrint('$_debugTag Starting voice recording');
      await _voiceService.startRecording(fieldId: _resolvedFieldId);
      _startMaxDurationTimer();
      _startAmplitudeMonitor();
    } catch (e) {
      debugPrint('$_debugTag Error starting recording: $e');
      if (mounted) {
        setState(() {
          _voiceFailed = true;
          _lastError = e.toString();
        });
      }
      _showErrorDialog('Failed to start recording', e.toString());
    }
  }

  Future<void> _stopAndTranscribe({required String trigger}) async {
    if (_isStoppingRecording || _hasSentTranscription) {
      debugPrint('$_debugTag Skipping stop for $trigger: already stopping/uploading');
      return;
    }

    _isStoppingRecording = true;
    _cancelRecordingMonitors();

    try {
      debugPrint('$_debugTag Stopping recording and transcribing ($trigger)');

      final audioPath = await _voiceService.stopRecording();
      if (audioPath == null || audioPath.isEmpty) {
        throw VoiceRecordingException(
          message: 'No recording path available',
          errorCode: 'NO_RECORDING_PATH',
        );
      }

      _hasSentTranscription = true;
      final transcribedText = await _voiceService.transcribeAudio(
        audioPath,
        fieldId: _resolvedFieldId,
      );

      final cleanedText = SpeechTextNormalizer.cleanNumericTranscription(transcribedText);
      final normalizedText = SpeechTextNormalizer.normalize(
        transcribedText,
        mode: VoiceInputMode.numeric,
      );
      final isValid = NumericVoiceValidator.isValid(normalizedText);

      debugPrint('$_debugTag Raw transcription: "$transcribedText"');
      debugPrint('$_debugTag Cleaned transcription: "$cleanedText"');
      debugPrint('$_debugTag Normalized transcription: "$normalizedText"');
      debugPrint('$_debugTag Validation result: $isValid');

      if (!isValid) {
        _handleInvalidNumericVoice();
        return;
      }

      if (mounted) {
        setState(() {
          _controller.value = TextEditingValue(
            text: normalizedText,
            selection: TextSelection.collapsed(offset: normalizedText.length),
          );
          _voiceFailed = false;
          _lastError = null;
        });
        widget.onPressureChanged(normalizedText);
        FocusScope.of(context).unfocus();
      }

      debugPrint('$_debugTag Voice input successful: "$transcribedText" -> "$normalizedText"');
    } on VoiceRecordingException catch (e) {
      debugPrint('$_debugTag Voice recording error: ${e.message}');
      if (mounted) {
        setState(() {
          _voiceFailed = true;
          _lastError = e.message;
        });
      }
      _showErrorDialog(
        'Voice transcription failed',
        _getFriendlyErrorMessage(e.errorCode),
      );
    } catch (e) {
      debugPrint('$_debugTag Unexpected error: $e');
      if (mounted) {
        setState(() {
          _voiceFailed = true;
          _lastError = e.toString();
        });
      }
      _showErrorDialog('Voice transcription failed', e.toString());
    } finally {
      _isStoppingRecording = false;
    }
  }

  void _handleInvalidNumericVoice() {
    if (!mounted) return;

    setState(() {
      _voiceFailed = true;
      _lastError = NumericVoiceValidator.invalidVoiceMessage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Numeric input required'),
      ),
    );
  }

  void _startAmplitudeMonitor() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _voiceService
        .amplitudeStream(interval: VoiceRecordingService.defaultAmplitudeInterval)
        .listen((db) {
      if (!_isRecording || _isStoppingRecording) {
        return;
      }

      if (db > _speechThresholdDb) {
        _speechDetected = true;
        _silenceTimer?.cancel();
        _silenceTimer = null;
        return;
      }

      if (_speechDetected && _silenceTimer == null) {
        _silenceTimer = Timer(_silenceTimeout, () {
          _stopAndTranscribe(trigger: 'silence-timeout');
        });
      }
    }, onError: (Object error) {
      debugPrint('$_debugTag Amplitude monitor error: $error');
    });
  }

  void _startMaxDurationTimer() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(_maxRecordingDuration, () {
      _stopAndTranscribe(trigger: 'max-duration');
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

  String _getFriendlyErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'NO_SPEECH_DETECTED':
        return 'No speech detected. Please speak clearly and try again.';
      case 'PERMISSION_DENIED':
        return 'Microphone permission is required for voice input.';
      case 'START_FAILED':
        return 'Could not start recording. Please try again.';
      case 'STOP_FAILED':
        return 'Could not stop recording. Please try again.';
      case 'GROQ_ERROR_MISSING_API_KEY':
        return 'Voice transcription is not configured. Please contact support.';
      case 'GROQ_ERROR_BAD_RESPONSE':
        return 'Transcription service error. Please try again.';
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
        return 'Network error. Please check your internet connection.';
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

  Widget _buildMicButton() {
    if (_voiceFailed) {
      return GestureDetector(
        onTap: _handleMicTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.mic_off, color: Colors.red.shade600, size: 20),
        ),
      );
    }

    if (_isTranscribing) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isRecording) {
      return GestureDetector(
        onTap: _handleMicTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.graphic_eq, color: Colors.red.shade600, size: 20),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleMicTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.mic_none, color: Colors.grey[600], size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-.]')),
          ],
          onChanged: widget.onPressureChanged,
          decoration: InputDecoration(
            labelText: 'Pressure (PSI)',
            hintText: 'Enter pressure in PSI (e.g. 2000-2200)',
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _isRecording || _isTranscribing ? Colors.blue : Colors.grey,
                width: _isRecording || _isTranscribing ? 2 : 1,
              ),
            ),
            suffixIcon: _buildMicButton(),
            helperText: 'Enter pressure in PSI or use the microphone',
            helperMaxLines: 1,
          ),
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Listening... stop speaking to auto-submit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_isTranscribing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Transcribing audio...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_voiceFailed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastError == null
                          ? 'Tap the mic to try voice input again.'
                          : 'Voice input failed. You can type the pressure manually.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
