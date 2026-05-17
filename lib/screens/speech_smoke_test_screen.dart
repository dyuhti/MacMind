import 'package:flutter/material.dart';

import '../widgets/voice_input_mic_button.dart';

class SpeechSmokeTestScreen extends StatefulWidget {
  const SpeechSmokeTestScreen({super.key});

  @override
  State<SpeechSmokeTestScreen> createState() => _SpeechSmokeTestScreenState();
}

class _SpeechSmokeTestScreenState extends State<SpeechSmokeTestScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Smoke Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this simple screen to verify speech recognition before testing in calculator forms.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Speech Input',
                hintText: 'Tap mic and speak',
                border: const OutlineInputBorder(),
                suffixIcon: VoiceInputMicButton(
                  controller: _controller,
                  fieldLabel: 'Speech Smoke Test',
                  fieldId: 'speech-smoke-test',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If speech fails: Speech recognition unavailable. Please type manually.',
              style: TextStyle(color: Color(0xFFB45309)),
            ),
          ],
        ),
      ),
    );
  }
}
