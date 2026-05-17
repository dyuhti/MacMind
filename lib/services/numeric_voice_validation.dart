class SpeechNumberParser {
  static const Map<String, int> _digitWords = {
    'zero': 0,
    'oh': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
  };

  static const Map<String, int> _smallNumbers = {
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };

  static const Map<String, int> _tensNumbers = {
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  static const Map<String, int> _scaleNumbers = {
    'hundred': 100,
    'thousand': 1000,
    'million': 1000000,
  };

  static const Set<String> _unitSuffixes = {
    'g',
    'gram',
    'grams',
    'kg',
    'kilogram',
    'kilograms',
    'mg',
    'mcg',
    'ml',
    'l',
    'liter',
    'liters',
    'litre',
    'litres',
    'minute',
    'minutes',
    'min',
    'mins',
    'hour',
    'hours',
    'hr',
    'hrs',
    'second',
    'seconds',
    'sec',
    'secs',
    'percent',
    'percentage',
    'bpm',
    'unit',
    'units',
  };

  static const Set<String> _ignorableTokens = {
    'and',
    'the',
    'a',
    'an',
    'per',
    'for',
    'of',
  };

  static final RegExp _numericLiteralPattern = RegExp(
    r'^[+-]?(?:\d+(?:\.\d+)?|\.\d+)(?:[eE][+-]?\d+)?$',
  );

  static String? parse(String input) {
    final literal = _parseNumericLiteral(input);
    if (literal != null) {
      return literal;
    }

    final normalized = _normalize(input);
    if (normalized.isEmpty) {
      return null;
    }

    final tokens = _dedupeConsecutiveTokens(_tokenize(normalized));
    if (tokens.isEmpty) {
      return null;
    }

    var total = 0;
    var current = 0;
    var sawNumericToken = false;
    var inDecimalPart = false;
    var suffixStarted = false;
    String? literalNumber;
    final decimalBuffer = StringBuffer();

    for (final token in tokens) {
      if (_ignorableTokens.contains(token)) {
        if (sawNumericToken || suffixStarted) {
          continue;
        }
        return null;
      }

      if (suffixStarted) {
        if (_unitSuffixes.contains(token)) {
          continue;
        }
        return null;
      }

      if (_unitSuffixes.contains(token)) {
        if (!sawNumericToken) {
          return null;
        }
        suffixStarted = true;
        continue;
      }

      if (_numericLiteralPattern.hasMatch(token)) {
        if (literalNumber != null || current != 0 || total != 0 || inDecimalPart) {
          return null;
        }
        literalNumber = _parseNumericLiteral(token);
        if (literalNumber == null) {
          return null;
        }
        sawNumericToken = true;
        continue;
      }

      if (token == 'point' || token == 'dot') {
        if (inDecimalPart) {
          return null;
        }
        if (!sawNumericToken && current == 0) {
          sawNumericToken = true;
        }
        inDecimalPart = true;
        continue;
      }

      if (inDecimalPart) {
        final decimalDigit = _decimalDigitOf(token);
        if (decimalDigit == null) {
          return null;
        }
        decimalBuffer.write(decimalDigit);
        sawNumericToken = true;
        continue;
      }

      final tokenValue = _wholeTokenValue(token);
      if (tokenValue == null) {
        return null;
      }

      sawNumericToken = true;
      if (tokenValue.scale != null) {
        final scale = tokenValue.scale!;
        if (current == 0) {
          current = 1;
        }
        current *= scale;
        if (scale >= 1000) {
          total += current;
          current = 0;
        }
      } else {
        current += tokenValue.value!;
      }
    }

    if (!sawNumericToken) {
      return null;
    }

    if (inDecimalPart && decimalBuffer.isEmpty) {
      return null;
    }

    if (literalNumber != null) {
      return literalNumber;
    }

    final wholeValue = total + current;
    if (inDecimalPart) {
      return '$wholeValue.${decimalBuffer.toString()}';
    }

    return wholeValue.toString();
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[,_]'), ' ')
        .replaceAll(RegExp(r'[-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _parseNumericLiteral(String input) {
    final literal = input.trim().replaceAll(',', '').replaceAll(RegExp(r'[.]+$'), '');
    if (literal.isEmpty) {
      return null;
    }

    if (!_numericLiteralPattern.hasMatch(literal)) {
      return null;
    }

    final parsed = num.tryParse(literal);
    if (parsed == null) {
      return null;
    }

    if (parsed is int) {
      return parsed.toString();
    }

    final text = parsed.toDouble().toString();
    return text.contains('.')
        ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : text;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    for (final rawToken in input.split(' ')) {
      final token = rawToken
          .replaceAll(RegExp(r'^[^a-z0-9.+-]+'), '')
          .replaceAll(RegExp(r'[^a-z0-9.+-]+$'), '');
      if (token.isEmpty) {
        continue;
      }
      tokens.add(token);
    }
    return tokens;
  }

  static List<String> _dedupeConsecutiveTokens(List<String> tokens) {
    if (tokens.isEmpty) {
      return tokens;
    }

    final output = <String>[];
    String? previous;

    for (final token in tokens) {
      if (token == previous) {
        continue;
      }
      output.add(token);
      previous = token;
    }

    return output;
  }

  static _TokenValue? _wholeTokenValue(String token) {
    final digit = _digitWords[token];
    if (digit != null) {
      return _TokenValue(value: digit);
    }

    final small = _smallNumbers[token];
    if (small != null) {
      return _TokenValue(value: small);
    }

    final tens = _tensNumbers[token];
    if (tens != null) {
      return _TokenValue(value: tens);
    }

    final scale = _scaleNumbers[token];
    if (scale != null) {
      return _TokenValue(scale: scale);
    }

    final parsed = int.tryParse(token);
    if (parsed != null) {
      return _TokenValue(value: parsed);
    }

    return null;
  }

  static int? _decimalDigitOf(String token) {
    final digit = _digitWords[token];
    if (digit != null) {
      return digit;
    }

    if (RegExp(r'^\d$').hasMatch(token)) {
      return int.tryParse(token);
    }

    return null;
  }
}

class NumericVoiceValidator {
  static const String invalidVoiceMessage = 'Please speak numeric values only';

  static String? sanitize(String input) {
    final parsed = SpeechNumberParser.parse(input);
    if (parsed == null) {
      return null;
    }

    return num.tryParse(parsed) == null ? null : parsed;
  }

  static bool isValid(String input) {
    return sanitize(input) != null;
  }
}

class _TokenValue {
  final int? value;
  final int? scale;

  const _TokenValue({this.value, this.scale});
}