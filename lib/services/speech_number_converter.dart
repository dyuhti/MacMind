class SpeechNumberConverter {
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

  static String? convert(String input) {
    final literal = _normalizeNumericLiteral(input);
    if (literal != null) {
      return literal;
    }

    final tokens = _tokenize(input);
    if (tokens.isEmpty) return null;

    if (tokens.every(_isSimpleDigitToken)) {
      final digits = tokens.map(_digitValueOf).toList();
      if (digits.toSet().length == 1) {
        return digits.first.toString();
      }
      return digits.join();
    }

    final pointIndex = tokens.indexOf('point');
    if (pointIndex != -1) {
      final integerTokens = tokens.take(pointIndex).toList();
      final decimalTokens = tokens.skip(pointIndex + 1).toList();

      final integerValue = integerTokens.isEmpty ? 0 : _parseWholeNumber(integerTokens);
      final decimalValue = _parseDecimalDigits(decimalTokens);

      if (integerValue == null || decimalValue == null || decimalValue.isEmpty) {
        return null;
      }

      return '$integerValue.$decimalValue';
    }

    return _parseWholeNumber(tokens);
  }

  static List<String> _tokenize(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return const [];

    final tokens = <String>[];
    for (final rawToken in normalized.split(' ')) {
      final token = rawToken
          .replaceAll(',', '')
          .replaceAll(RegExp(r'^[^a-z0-9.]+'), '')
          .replaceAll(RegExp(r'[^a-z0-9.]+$'), '')
          .replaceAll(RegExp(r'\.+$'), '');

      if (token.isEmpty || token == 'and') {
        continue;
      }

      tokens.add(token);
    }

    return tokens;
  }

  static String? _normalizeNumericLiteral(String input) {
    var literal = input.toLowerCase().trim().replaceAll(',', '');
    literal = literal.replaceAll(RegExp(r'[.]+$'), '');

    if (literal.isEmpty) return null;

    if (RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(literal)) {
      return literal;
    }

    return null;
  }

  static String? _parseWholeNumber(List<String> tokens) {
    if (tokens.isEmpty) return null;

    var total = 0;
    var current = 0;
    var sawNumericToken = false;

    for (final token in tokens) {
      if (_digitWords.containsKey(token)) {
        current += _digitWords[token]!;
        sawNumericToken = true;
        continue;
      }

      if (_smallNumbers.containsKey(token)) {
        current += _smallNumbers[token]!;
        sawNumericToken = true;
        continue;
      }

      if (_tensNumbers.containsKey(token)) {
        current += _tensNumbers[token]!;
        sawNumericToken = true;
        continue;
      }

      if (_scaleNumbers.containsKey(token)) {
        sawNumericToken = true;
        final scale = _scaleNumbers[token]!;
        if (current == 0) {
          current = 1;
        }
        current *= scale;
        if (scale >= 1000) {
          total += current;
          current = 0;
        }
        continue;
      }

      if (_isMultiDigitNumber(token)) {
        final parsed = int.tryParse(token);
        if (parsed == null) {
          return null;
        }
        sawNumericToken = true;
        current = current == 0 ? parsed : (current * 10) + parsed;
        continue;
      }

      return null;
    }

    if (!sawNumericToken) {
      return null;
    }

    total += current;
    return total.toString();
  }

  static String? _parseDecimalDigits(List<String> tokens) {
    if (tokens.isEmpty) return null;

    final buffer = StringBuffer();
    for (final token in tokens) {
      if (_digitWords.containsKey(token)) {
        buffer.write(_digitWords[token]);
        continue;
      }

      if (_isMultiDigitNumber(token)) {
        buffer.write(token);
        continue;
      }

      return null;
    }

    return buffer.toString();
  }

  static bool _isSimpleDigitToken(String token) {
    return _digitWords.containsKey(token) || _isSingleDigitNumber(token);
  }

  static bool _isSingleDigitNumber(String token) {
    return RegExp(r'^\d$').hasMatch(token);
  }

  static bool _isMultiDigitNumber(String token) {
    return RegExp(r'^\d+$').hasMatch(token);
  }

  static int _digitValueOf(String token) {
    if (_digitWords.containsKey(token)) {
      return _digitWords[token]!;
    }
    return int.parse(token);
  }
}