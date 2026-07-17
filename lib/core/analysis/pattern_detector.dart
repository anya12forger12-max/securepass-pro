enum PatternType {
  repeatedChars,
  sequentialChars,
  keyboardPattern,
  repeatedWords,
  predictableStructure,
  excessiveSymmetry,
  commonSubstitution,
  weakRepetition,
  repeatedGroups,
  datePattern,
  dictionaryWord,
}

class DetectedPattern {
  final PatternType type;
  final String description;
  final int startIndex;
  final int length;
  final String severity;

  const DetectedPattern({
    required this.type,
    required this.description,
    required this.startIndex,
    required this.length,
    required this.severity,
  });
}

class PatternDetector {
  static final PatternDetector instance = PatternDetector._();

  const PatternDetector._();

  List<DetectedPattern> detect(String password) {
    if (password.isEmpty) return [];

    final List<DetectedPattern> patterns = [];

    patterns.addAll(_detectRepeatedChars(password));
    patterns.addAll(_detectSequentialChars(password));
    patterns.addAll(_detectKeyboardPatterns(password));
    patterns.addAll(_detectRepeatedWords(password));
    patterns.addAll(_detectPredictableStructure(password));
    patterns.addAll(_detectExcessiveSymmetry(password));
    patterns.addAll(_detectCommonSubstitutions(password));
    patterns.addAll(_detectWeakRepetition(password));
    patterns.addAll(_detectRepeatedGroups(password));
    patterns.addAll(_detectDatePatterns(password));
    patterns.addAll(_detectDictionaryWords(password));

    return patterns;
  }

  List<DetectedPattern> _detectRepeatedChars(String password) {
    final List<DetectedPattern> patterns = [];
    int i = 0;

    while (i < password.length) {
      int runLength = 1;
      while (i + runLength < password.length &&
          password.codeUnitAt(i + runLength) == password.codeUnitAt(i)) {
        runLength++;
      }

      if (runLength >= 2) {
        final String char = password[i];
        String severity;
        if (runLength >= 5) {
          severity = 'high';
        } else if (runLength >= 3) {
          severity = 'medium';
        } else {
          severity = 'low';
        }

        patterns.add(DetectedPattern(
          type: PatternType.repeatedChars,
          description: 'Character "$char" repeated $runLength times',
          startIndex: i,
          length: runLength,
          severity: severity,
        ));
      }

      i += runLength;
    }

    return patterns;
  }

  List<DetectedPattern> _detectSequentialChars(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    for (int i = 0; i <= lower.length - 3; i++) {
      int seqLen = 0;
      for (int j = i; j < lower.length - 1; j++) {
        if (lower.codeUnitAt(j + 1) - lower.codeUnitAt(j) == 1) {
          seqLen++;
        } else if (lower.codeUnitAt(j) - lower.codeUnitAt(j + 1) == 1) {
          seqLen++;
        } else {
          break;
        }
      }

      if (seqLen >= 2) {
        String severity;
        if (seqLen >= 4) {
          severity = 'high';
        } else if (seqLen >= 3) {
          severity = 'medium';
        } else {
          severity = 'low';
        }

        patterns.add(DetectedPattern(
          type: PatternType.sequentialChars,
          description: 'Sequential characters "${password.substring(i, (i + seqLen + 1).clamp(0, password.length))}"',
          startIndex: i,
          length: seqLen + 1,
          severity: severity,
        ));

        i += seqLen;
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectKeyboardPatterns(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    final List<String> keyboardSequences = [
      'qwerty', 'qwertz', 'asdf', 'zxcv', 'qazwsx',
      'wasd', 'qweasd', 'asdqwe', 'zxcasd', 'qweasdzxc',
      '1234', '0987', '4321', '7890',
    ];

    for (final String sequence in keyboardSequences) {
      int index = lower.indexOf(sequence);
      while (index != -1) {
        patterns.add(DetectedPattern(
          type: PatternType.keyboardPattern,
          description: 'Keyboard pattern "$sequence" found',
          startIndex: index,
          length: sequence.length,
          severity: sequence.length >= 5 ? 'high' : 'medium',
        ));
        index = lower.indexOf(sequence, index + 1);
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectRepeatedWords(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    final List<String> separators = ['-', '_', '.', ' ', ',', ':', ';', '/', '@', '#'];

    for (final String separator in separators) {
      if (lower.contains(separator)) {
        final List<String> parts = lower.split(separator);
        final Map<String, List<int>> wordPositions = {};

        for (int i = 0; i < parts.length; i++) {
          if (parts[i].length >= 2) {
            wordPositions.putIfAbsent(parts[i], () => []).add(i);
          }
        }

        for (final entry in wordPositions.entries) {
          if (entry.value.length > 1) {
            int pos = 0;
            for (int i = 0; i < entry.value[0]; i++) {
              pos += parts[i].length + 1;
            }

            patterns.add(DetectedPattern(
              type: PatternType.repeatedWords,
              description: 'Word "${entry.key}" repeated ${entry.value.length} times',
              startIndex: pos,
              length: entry.key.length,
              severity: 'high',
            ));
          }
        }
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectPredictableStructure(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    bool allLowerDigit = true;
    for (final int codeUnit in lower.codeUnits) {
      if (!((codeUnit >= 97 && codeUnit <= 122) || (codeUnit >= 48 && codeUnit <= 57))) {
        allLowerDigit = false;
        break;
      }
    }

    if (allLowerDigit && password.length >= 4) {
      bool hasLower = false;
      bool hasDigit = false;
      for (final int codeUnit in password.codeUnits) {
        if (codeUnit >= 97 && codeUnit <= 122) hasLower = true;
        if (codeUnit >= 48 && codeUnit <= 57) hasDigit = true;
      }

      if (hasLower && hasDigit) {
        patterns.add(DetectedPattern(
          type: PatternType.predictableStructure,
          description: 'Predictable structure: lowercase letters followed by digits',
          startIndex: 0,
          length: password.length,
          severity: 'medium',
        ));
      }
    }

    bool allUpperDigit = true;
    for (final int codeUnit in password.codeUnits) {
      if (!((codeUnit >= 65 && codeUnit <= 90) || (codeUnit >= 48 && codeUnit <= 57))) {
        allUpperDigit = false;
        break;
      }
    }

    if (allUpperDigit && password.length >= 4) {
      patterns.add(DetectedPattern(
        type: PatternType.predictableStructure,
        description: 'Predictable structure: uppercase letters mixed with digits only',
        startIndex: 0,
        length: password.length,
        severity: 'medium',
      ));
    }

    return patterns;
  }

  List<DetectedPattern> _detectExcessiveSymmetry(String password) {
    final List<DetectedPattern> patterns = [];

    if (password.length < 3) return patterns;

    final String lower = password.toLowerCase();
    bool isPalindrome = true;

    for (int i = 0; i < lower.length ~/ 2; i++) {
      if (lower[i] != lower[lower.length - 1 - i]) {
        isPalindrome = false;
        break;
      }
    }

    if (isPalindrome) {
      patterns.add(DetectedPattern(
        type: PatternType.excessiveSymmetry,
        description: 'Password is a palindrome',
        startIndex: 0,
        length: password.length,
        severity: password.length >= 6 ? 'medium' : 'low',
      ));
    }

    return patterns;
  }

  List<DetectedPattern> _detectCommonSubstitutions(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    final Map<String, String> substitutions = {
      '@': 'a',
      '3': 'e',
      '5': 's',
      '0': 'o',
      '1': 'l',
      '4': 'a',
      '8': 'b',
      '7': 't',
      '9': 'g',
      '2': 'z',
      r'$': 's',
      '!': 'i',
      '+': 't',
    };

    String deobfuscated = '';
    for (final String char in lower.split('')) {
      if (substitutions.containsKey(char)) {
        deobfuscated += substitutions[char]!;
      } else {
        deobfuscated += char;
      }
    }

    final List<String> commonPatterns = [
      'password', 'letmein', 'welcome', 'monkey', 'master',
      'dragon', 'login', 'admin', 'shadow', 'sunshine',
      'princess', 'football', 'trustno1', 'iloveyou',
      'batman', 'access', 'hello', 'charlie', 'donald',
    ];

    for (final String pattern in commonPatterns) {
      if (deobfuscated.contains(pattern) && lower != pattern) {
        patterns.add(DetectedPattern(
          type: PatternType.commonSubstitution,
          description: 'Common word "$pattern" with character substitutions',
          startIndex: 0,
          length: password.length,
          severity: 'high',
        ));
        break;
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectWeakRepetition(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    for (int patternLen = 1; patternLen <= lower.length ~/ 2; patternLen++) {
      bool isRepeating = true;
      if (lower.length < patternLen * 2) continue;

      final String pattern = lower.substring(0, patternLen);

      for (int i = patternLen; i < lower.length; i++) {
        if (lower[i] != pattern[i % patternLen]) {
          isRepeating = false;
          break;
        }
      }

      if (isRepeating && patternLen < lower.length) {
        int repetitions = lower.length ~/ patternLen;
        if (repetitions >= 2) {
          patterns.add(DetectedPattern(
            type: PatternType.weakRepetition,
            description: 'Pattern "$pattern" repeated $repetitions times',
            startIndex: 0,
            length: lower.length,
            severity: repetitions >= 4 ? 'high' : 'medium',
          ));
        }
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectRepeatedGroups(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    for (int groupLen = 2; groupLen <= lower.length ~/ 2; groupLen++) {
      for (int start = 0; start <= lower.length - groupLen * 2; start++) {
        final String group = lower.substring(start, start + groupLen);
        final String nextGroup = lower.substring(start + groupLen, start + groupLen * 2);

        if (group == nextGroup) {
          int count = 2;
          int pos = start + groupLen * 2;

          while (pos + groupLen <= lower.length) {
            final String next = lower.substring(pos, pos + groupLen);
            if (next == group) {
              count++;
              pos += groupLen;
            } else {
              break;
            }
          }

          if (count >= 2) {
            patterns.add(DetectedPattern(
              type: PatternType.repeatedGroups,
              description: 'Group "$group" repeated $count times',
              startIndex: start,
              length: groupLen * count,
              severity: count >= 3 ? 'high' : 'medium',
            ));
          }
        }
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectDatePatterns(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    final List<String> months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];

    for (final String month in months) {
      int idx = lower.indexOf(month);
      if (idx != -1) {
        patterns.add(DetectedPattern(
          type: PatternType.datePattern,
          description: 'Month name "$month" detected',
          startIndex: idx,
          length: month.length,
          severity: 'medium',
        ));
      }
    }

    if (password.length >= 4) {
      for (int i = 0; i <= password.length - 4; i++) {
        final String chunk = password.substring(i, i + 4);
        final int? year = int.tryParse(chunk);
        if (year != null && year >= 1900 && year <= 2100) {
          patterns.add(DetectedPattern(
            type: PatternType.datePattern,
            description: 'Possible year "$year" detected',
            startIndex: i,
            length: 4,
            severity: 'low',
          ));
          break;
        }
      }
    }

    return patterns;
  }

  List<DetectedPattern> _detectDictionaryWords(String password) {
    final List<DetectedPattern> patterns = [];
    final String lower = password.toLowerCase();

    final List<String> dictionaryWords = [
      'password', 'letmein', 'welcome', 'monkey', 'master',
      'dragon', 'login', 'admin', 'shadow', 'sunshine',
      'princess', 'football', 'trustno1', 'iloveyou',
      'batman', 'access', 'hello', 'charlie', 'donald',
      'qwerty', 'abc123', 'passw0rd', 'starwars',
      'mustang', 'michael', 'ashley', 'jessica', 'pepper',
      'ranger', 'buster', 'thomas', 'hockey', 'killer',
      'george', 'sexy', 'andrew', 'joshua', 'bailey',
      'hunter', 'biteme', 'ashley1', 'soccer', 'anthony',
    ];

    for (final String word in dictionaryWords) {
      int idx = lower.indexOf(word);
      if (idx != -1) {
        String severity;
        if (lower == word) {
          severity = 'high';
        } else if (idx == 0 || idx == lower.length - word.length) {
          severity = 'high';
        } else {
          severity = 'medium';
        }

        patterns.add(DetectedPattern(
          type: PatternType.dictionaryWord,
          description: 'Dictionary word "$word" found',
          startIndex: idx,
          length: word.length,
          severity: severity,
        ));
      }
    }

    return patterns;
  }
}
