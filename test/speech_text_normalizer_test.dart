import 'package:flutter_test/flutter_test.dart';

import 'package:med_calci_app/services/speech_number_converter.dart';
import 'package:med_calci_app/services/speech_text_normalizer.dart';

void main() {
  group('SpeechNumberConverter', () {
    test('converts common spoken numbers into digits', () {
      expect(SpeechNumberConverter.convert('five.'), '5');
      expect(SpeechNumberConverter.convert('two.'), '2');
      expect(SpeechNumberConverter.convert('ten'), '10');
      expect(SpeechNumberConverter.convert('twenty'), '20');
      expect(SpeechNumberConverter.convert('two thousand'), '2000');
      expect(SpeechNumberConverter.convert('four point five'), '4.5');
      expect(SpeechNumberConverter.convert('zero point six.'), '0.6');
      expect(SpeechNumberConverter.convert('one hundred twenty'), '120');
      expect(SpeechNumberConverter.convert('two two two'), '2');
    });

    test('accepts already numeric text', () {
      expect(SpeechNumberConverter.convert('0.6.'), '0.6');
      expect(SpeechNumberConverter.convert('2000'), '2000');
    });
  });

  test('keeps natural text unchanged in text mode', () {
    expect(
      SpeechTextNormalizer.normalize('John Smith', mode: VoiceInputMode.text),
      'John Smith',
    );
  });

  test('numeric mode normalizes spoken digits and decimals', () {
    expect(
      SpeechTextNormalizer.normalize('Five.', mode: VoiceInputMode.numeric),
      '5',
    );
    expect(
      SpeechTextNormalizer.normalize('Zero point six.', mode: VoiceInputMode.numeric),
      '0.6',
    );
    expect(
      SpeechTextNormalizer.normalize('One hundred twenty', mode: VoiceInputMode.numeric),
      '120',
    );
  });
}