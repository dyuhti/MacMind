import 'numeric_voice_validation.dart';
import 'speech_number_converter.dart';

enum VoiceInputMode {
  auto,
  text,
  numeric,
}

class SpeechTextNormalizer {

  static String normalize(String input, {VoiceInputMode mode = VoiceInputMode.text}) {
    final cleaned = mode == VoiceInputMode.numeric
        ? cleanNumericTranscription(input)
        : cleanTranscription(input);
    if (cleaned.isEmpty || mode == VoiceInputMode.text) {
      return cleaned;
    }

    final numeric = NumericVoiceValidator.sanitize(cleaned) ?? SpeechNumberConverter.convert(cleaned);
    return numeric ?? cleaned;
  }

  static String cleanNumericTranscription(String input) {
    final compact = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return '';

    final words = compact
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .split(' ')
        .map((word) => word
            .replaceAll(RegExp(r'^[^a-z0-9.]+'), '')
            .replaceAll(RegExp(r'[^a-z0-9.]+$'), '')
            .replaceAll(RegExp(r'^\.+|\.+$'), ''))
        .where((word) => word.isNotEmpty)
        .toList();

    final deduped = _dedupeConsecutiveWords(words);
    final repeatedPhrase = _reduceRepeatedPhrase(deduped);
    return repeatedPhrase.join(' ');
  }

  static String cleanTranscription(String input) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return '';

    final words = _dedupeConsecutiveWords(compact.split(' '));
    final repeatedPhrase = _reduceRepeatedPhrase(words);
    return repeatedPhrase.join(' ');
  }

  static List<String> _reduceRepeatedPhrase(List<String> words) {
    if (words.length < 2) return words;

    final normalized = words.map((word) => word.toLowerCase()).toList();
    final maxPattern = words.length ~/ 2;

    for (int patternLength = 1; patternLength <= maxPattern; patternLength++) {
      if (words.length % patternLength != 0) continue;

      final pattern = normalized.sublist(0, patternLength);
      var repeated = true;

      for (int i = patternLength; i < normalized.length; i += patternLength) {
        final segment = normalized.sublist(i, i + patternLength);
        if (!_listEquals(pattern, segment)) {
          repeated = false;
          break;
        }
      }

      if (repeated) {
        return words.sublist(0, patternLength);
      }
    }

    return words;
  }

  static List<String> _dedupeConsecutiveWords(List<String> words) {
    if (words.isEmpty) return words;

    final output = <String>[];
    String? previous;

    for (final word in words) {
      final normalized = word.toLowerCase();
      if (normalized == previous) {
        continue;
      }
      output.add(word);
      previous = normalized;
    }

    return output;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}