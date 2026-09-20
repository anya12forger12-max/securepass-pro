import 'dart:math';

import 'package:uuid/uuid.dart';

import 'package:securepass_pro/core/crypto/char_generator.dart';
import 'package:securepass_pro/core/crypto/secure_random.dart';
import 'package:securepass_pro/domain/entities/generation_config.dart';
import 'package:securepass_pro/domain/entities/passphrase_config.dart';
import 'package:securepass_pro/domain/entities/pin_config.dart';
import 'package:securepass_pro/domain/enums/character_set_type.dart';

class CredentialGenerator {
  CredentialGenerator._();

  static final SecureRandom _random = SecureRandom.instance;
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Passwords
  // ---------------------------------------------------------------------------

  static String generatePassword(GenerationConfig config) {
    final length = max(config.length, 1);
    final sets = _enabledSets(config.charSets);
    if (sets.isEmpty) {
      return _randomString(length, CharSet.alphanumeric);
    }

    final baseCharset = sets.map(_charsetFor).join();
    final custom = _unique(config.customChars);
    final charsetSource = custom.isEmpty ? baseCharset : '$baseCharset$custom';
    final allowed = _applyExclusions(charsetSource, config.exclusions);
    if (allowed.isEmpty) {
      return _randomStringCastFrom(length, sets);
    }

    const maxAttempts = 24;
    var last = '';
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      last = _buildPasswordCandidate(
        length: length,
        sets: sets,
        allowed: allowed,
        config: config,
      );
      if (_passesPasswordChecks(last, sets, config)) {
        return last;
      }
    }
    return _passesPasswordChecks(last, sets, config)
        ? last
        : _randomString(length, allowed);
  }

  static List<CharacterSetType> _enabledSets(Set<CharacterSetType> sets) {
    final result = <CharacterSetType>[];
    for (final set in [
      CharacterSetType.uppercase,
      CharacterSetType.lowercase,
      CharacterSetType.numbers,
      CharacterSetType.symbols,
      CharacterSetType.extendedSymbols,
      CharacterSetType.spaces,
    ]) {
      if (sets.contains(set)) result.add(set);
    }
    return result;
  }

  static String _charsetFor(CharacterSetType set) {
    switch (set) {
      case CharacterSetType.uppercase:
        return CharSet.uppercase;
      case CharacterSetType.lowercase:
        return CharSet.lowercase;
      case CharacterSetType.numbers:
        return CharSet.digits;
      case CharacterSetType.symbols:
        return CharSet.symbols;
      case CharacterSetType.extendedSymbols:
        return CharSet.extendedSymbols;
      case CharacterSetType.spaces:
        return CharSet.space;
    }
  }

  static String _applyExclusions(String charset, Set<String> exclusions) {
    if (exclusions.isEmpty) return charset;
    final result = charset.split('').where((c) => !exclusions.contains(c)).join();
    return result;
  }

  static String _unique(String input) {
    final seen = <String>{};
    final result = input.split('').where(seen.add).join();
    return result;
  }

  static String _randomString(int length, String charset) {
    return CharGenerator.string(length, charset);
  }

  static String _randomStringCastFrom(int length, List<CharacterSetType> sets) {
    final charset = _charsetFor(sets.first);
    return _randomString(length, charset);
  }

  static String _buildPasswordCandidate({
    required int length,
    required List<CharacterSetType> sets,
    required String allowed,
    required GenerationConfig config,
  }) {
    final chars = <String>[];
    for (final set in sets) {
      final setCharset = _applyExclusions(_charsetFor(set), config.exclusions);
      if (setCharset.isEmpty) continue;
      final minimum = _minimumFor(set, config);
      for (var i = 0; i < minimum; i++) {
        chars.add(CharGenerator.fromCharset(setCharset));
      }
    }

    while (chars.length < length) {
      chars.add(_random.unbiasedElement(allowed.split('')));
    }
    if (chars.length > length) {
      chars.removeRange(length, chars.length);
    }

    _shuffle(chars);

    if (config.mustStartWith != null && chars.isNotEmpty) {
      final setCharset = _applyExclusions(
        _charsetFor(config.mustStartWith!),
        config.exclusions,
      );
      if (setCharset.isNotEmpty) {
        chars[0] = CharGenerator.fromCharset(setCharset);
      }
    }
    if (config.mustEndWith != null && chars.isNotEmpty) {
      final setCharset = _applyExclusions(
        _charsetFor(config.mustEndWith!),
        config.exclusions,
      );
      if (setCharset.isNotEmpty) {
        chars[chars.length - 1] = CharGenerator.fromCharset(setCharset);
      }
    }

    return chars.join();
  }

  static int _minimumFor(CharacterSetType set, GenerationConfig config) {
    int minimum = 1;
    switch (set) {
      case CharacterSetType.uppercase:
        minimum = max(minimum, config.minUppercase);
      case CharacterSetType.lowercase:
        minimum = max(minimum, config.minLowercase);
      case CharacterSetType.numbers:
        minimum = max(minimum, config.minNumbers);
      case CharacterSetType.symbols:
      case CharacterSetType.extendedSymbols:
        minimum = max(minimum, config.minSymbols);
      case CharacterSetType.spaces:
        break;
    }
    return minimum;
  }

  static void _shuffle(List<String> chars) {
    for (var i = chars.length - 1; i > 0; i--) {
      final j = _random.nextInt(0, i);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
  }

  static bool _passesPasswordChecks(
    String candidate,
    List<CharacterSetType> sets,
    GenerationConfig config,
  ) {
    if (config.length > 0 && candidate.length != config.length) return false;
    for (final set in sets) {
      final setCharset = _applyExclusions(_charsetFor(set), config.exclusions);
      if (setCharset.isEmpty) continue;
      final count = candidate.split('').where(setCharset.contains).length;
      if (count < _minimumFor(set, config)) return false;
    }
    if (config.minUniqueChars > 0 &&
        candidate.split('').toSet().length < config.minUniqueChars) {
      return false;
    }
    if (config.maxRepeated > 0 && _hasLongRun(candidate, config.maxRepeated)) {
      return false;
    }
    if (config.noConsecutive && _hasNeighbor(candidate)) {
      return false;
    }
    if (config.noSequential && _hasSequentialRun(candidate, 3)) {
      return false;
    }
    for (final excluded in config.exclusions) {
      if (candidate.contains(excluded)) return false;
    }
    return true;
  }

  static bool _hasLongRun(String value, int maxAllowed) {
    var run = 1;
    for (var i = 1; i < value.length; i++) {
      if (value[i] == value[i - 1]) {
        run++;
        if (run > maxAllowed) return true;
      } else {
        run = 1;
      }
    }
    return false;
  }

  static bool _hasNeighbor(String value) {
    for (var i = 1; i < value.length; i++) {
      final prev = value.codeUnitAt(i - 1);
      final curr = value.codeUnitAt(i);
      if (curr == prev + 1 || curr == prev - 1) return true;
    }
    return false;
  }

  static bool _hasSequentialRun(String value, int runLength) {
    var run = 1;
    for (var i = 1; i < value.length; i++) {
      final prev = value.codeUnitAt(i - 1);
      final curr = value.codeUnitAt(i);
      if (curr == prev + 1) {
        run++;
        if (run >= runLength) return true;
      } else {
        run = 1;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Passphrases
  // ---------------------------------------------------------------------------

  static String generatePassphrase(PassphraseConfig config) {
    final wordCount = max(config.wordCount, 1);
    final words = <String>[];
    for (var i = 0; i < wordCount; i++) {
      var word = _random.unbiasedElement(_passphraseWords);
      if (config.capitalize) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      words.add(word);
    }

    var parts = <String>[];
    final separator = config.separator.isNotEmpty ? config.separator : '-';
    if (config.includeNumber) {
      final index = _random.nextInt(0, words.length);
      final number = '${_random.nextInt(0, 99)}';
      parts = [...words];
      parts.insert(index, number);
    } else {
      parts = [...words];
    }
    if (config.includeSymbol) {
      parts.add(_random.unbiasedElement(_passphraseSymbols));
    }

    final body = parts.join(separator);
    return '${config.prefix}$body${config.suffix}';
  }

  static const List<String> _passphraseSymbols = [
    '!',
    '@',
    '#',
    '\$',
    '%',
    '^',
    '&',
    '*',
    '+',
    '?',
  ];

  static const List<String> _passphraseWords = [
    'apple', 'archer', 'aster', 'atlas', 'amber', 'arrow', 'anchor',
    'beacon', 'blossom', 'bridge', 'breeze', 'boulder', 'badger', 'banjo',
    'cactus', 'canyon', 'castle', 'cedar', 'chariot', 'cobalt', 'comet',
    'crimson', 'crystal', 'cyclone', 'dahlia', 'delta', 'desert', 'diamond',
    'dolphin', 'dune', 'eagle', 'ember', 'falcon', 'feather', 'fern', 'fjord',
    'flame', 'forest', 'fortress', 'foxglove', 'galaxy', 'garden', 'geyser',
    'glacier', 'granite', 'grass', 'guitar', 'harbor', 'harvest', 'horizon',
    'hummingbird', 'indigo', 'island', 'ivory', 'jasmine', 'jaguar', 'jubilee',
    'jungle', 'kelp', 'kingfisher', 'labyrinth', 'lagoon', 'lantern', 'lavender',
    'ledge', 'lemon', 'lightning', 'lily', 'lynx', 'maple', 'marble', 'meadow',
    'meander', 'meteor', 'mirage', 'mistral', 'moonbeam', 'mosaic', 'mountain',
    'nectar', 'newt', 'oasis', 'onyx', 'orchid', 'oriole', 'otter', 'palette',
    'palmtree', 'panorama', 'paragon', 'pearl', 'pebble', 'pelican', 'phoenix',
    'pixel', 'plateau', 'prairie', 'prism', 'quartz', 'quill', 'rainbow',
    'raven', 'reef', 'river', 'rivulet', 'saffron', 'sapphire', 'savanna',
    'scarlet', 'seahorse', 'sequoia', 'serenity', 'shadow', 'silhouette',
    'sienna', 'sierra', 'silver', 'skyline', 'slate', 'snowflake', 'solstice',
    'sparrow', 'spark', 'spartan', 'starling', 'sunflower', 'sunrise', 'sunset',
    'sycamore', 'taiga', 'tangerine', 'tempest', 'thunder', 'tidal', 'tiger',
    'tornado', 'turquoise', 'twilight', 'umbrella', 'valley', 'vantage', 'velvet',
    'verdict', 'violet', 'volcano', 'voyager', 'willow', 'winter', 'wolf',
    'zenith', 'zephyr', 'zircon',
  ];

  // ---------------------------------------------------------------------------
  // PINs
  // ---------------------------------------------------------------------------

  static String generatePin(PinConfig config) {
    final length = max(config.length, 1);
    const digits = '0123456789';

    var last = '';
    for (var attempt = 0; attempt < 24; attempt++) {
      last = _buildPinCandidate(length, config, digits);
      if (_passesPinChecks(last, config)) return last;
    }
    return _passesPinChecks(last, config) ? last : _randomString(length, digits);
  }

  static String _buildPinCandidate(
    int length,
    PinConfig config,
    String digits,
  ) {
    final pool = digits.split('');
    final chars = <String>[];
    for (var i = 0; i < length; i++) {
      var picked = '';
      for (var attempt = 0; attempt < 16; attempt++) {
        final candidate = _random.unbiasedElement(pool);
        final violatesRepeated = config.avoidRepeated &&
            chars.isNotEmpty && chars.last == candidate;
        final violatesSequential = config.avoidSequential &&
            chars.isNotEmpty &&
            (candidate.codeUnitAt(0) == chars.last.codeUnitAt(0) + 1 ||
                candidate.codeUnitAt(0) == chars.last.codeUnitAt(0) - 1);
        if (!violatesRepeated && !violatesSequential) {
          picked = candidate;
          break;
        }
      }
      if (picked.isEmpty) {
        break;
      }
      chars.add(picked);
    }
    return chars.join();
  }

  static bool _passesPinChecks(String candidate, PinConfig config) {
    if (config.length > 0 && candidate.length != config.length) return false;
    for (var i = 1; i < candidate.length; i++) {
      if (config.avoidRepeated && candidate[i] == candidate[i - 1]) {
        return false;
      }
      if (config.avoidSequential &&
          (candidate.codeUnitAt(i) == candidate.codeUnitAt(i - 1) + 1 ||
              candidate.codeUnitAt(i) == candidate.codeUnitAt(i - 1) - 1)) {
        return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // UUIDs
  // ---------------------------------------------------------------------------

  static String generateUuidV4() => _uuid.v4();
}