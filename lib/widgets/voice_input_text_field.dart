import 'package:flutter/material.dart';

import '../services/speech_text_normalizer.dart';
import '../services/voice_recording_service.dart';
import 'voice_input_mic_button.dart';

/// Reusable text field with an isolated voice input mic.
///
/// Each instance tracks its own active field state and only reacts when its
/// field ID is the current active voice session.
class VoiceInputTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String fieldId;
  final String hintText;
  final TextInputType keyboardType;
  final VoiceInputMode voiceInputMode;
  final int maxLines;
  final int minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onFieldSubmitted;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool enabled;
  final int? maxLength;
  final void Function(String fieldId, String message)? onInvalidVoiceInput;

  const VoiceInputTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldId,
    this.hintText = '',
    this.keyboardType = TextInputType.text,
    this.voiceInputMode = VoiceInputMode.auto,
    this.maxLines = 1,
    this.minLines = 1,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.nextFocusNode,
    this.enabled = true,
    this.maxLength,
    this.onInvalidVoiceInput,
  });

  @override
  State<VoiceInputTextField> createState() => _VoiceInputTextFieldState();
}

class _VoiceInputTextFieldState extends State<VoiceInputTextField> {
  late final VoiceRecordingService _voiceService;
  bool _isActive = false;

  VoiceInputMode get _resolvedVoiceMode {
    if (widget.voiceInputMode != VoiceInputMode.auto) {
      return widget.voiceInputMode;
    }

    final keyboard = widget.keyboardType;
    final isNumericKeyboard = keyboard == TextInputType.number ||
        keyboard == const TextInputType.numberWithOptions(decimal: true) ||
        keyboard == const TextInputType.numberWithOptions(signed: true) ||
        keyboard == const TextInputType.numberWithOptions(decimal: true, signed: true);

    return isNumericKeyboard ? VoiceInputMode.numeric : VoiceInputMode.text;
  }

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _isActive = _voiceService.activeFieldId == widget.fieldId;
    _voiceService.activeFieldIdNotifier.addListener(_syncActiveState);
  }

  @override
  void dispose() {
    _voiceService.activeFieldIdNotifier.removeListener(_syncActiveState);
    super.dispose();
  }

  void _syncActiveState() {
    if (!mounted) return;
    final nextActive = _voiceService.activeFieldId == widget.fieldId;
    if (nextActive != _isActive) {
      setState(() => _isActive = nextActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onFieldSubmitted?.call(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: _isActive ? const Color(0xFFF8FAFF) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isActive ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
                width: _isActive ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E5F9A), width: 1.5),
            ),
            suffixIcon: VoiceInputMicButton(
              controller: widget.controller,
              fieldLabel: widget.label,
              fieldId: widget.fieldId,
              nextFocusNode: widget.nextFocusNode,
              voiceInputMode: _resolvedVoiceMode,
              onInvalidVoiceInput: widget.onInvalidVoiceInput,
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}