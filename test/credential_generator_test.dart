import 'package:flutter_test/flutter_test.dart';

import 'package:securepass_pro/core/crypto/credential_generator.dart';
import 'package:securepass_pro/domain/entities/generation_config.dart';
import 'package:securepass_pro/domain/entities/passphrase_config.dart';
import 'package:securepass_pro/domain/entities/pin_config.dart';

void main() {
  group('PasswordGenerator', () {
    test('respects length and includes one char from every enabled set', () {
      for (var run = 0; run < 100; run++) {
        final password = CredentialGenerator.generatePassword(
          const GenerationConfig(),
        );
        expect(password.length, 24);
        expect(password.contains(RegExp('[A-Z]')), isTrue);
        expect(password.contains(RegExp('[a-z]')), isTrue);
        expect(password.contains(RegExp('[0-9]')), isTrue);
        expect(
          password.contains(RegExp('[^A-Za-z0-9]')),
          isTrue,
        );
      }
    });

    test('excludes ambiguous characters when configured', () {
      for (var run = 0; run < 50; run++) {
        final password = CredentialGenerator.generatePassword(
          const GenerationConfig(
            exclusions: {'O', '0', 'I', 'l', '1'},
          ),
        );
        expect(password.contains(RegExp('[O0Il1]')), isFalse);
        expect(password.length, 24);
      }
    });

    test('honors minUniqueChars and maxRepeated constraints', () {
      for (var run = 0; run < 50; run++) {
        final password = CredentialGenerator.generatePassword(
          const GenerationConfig(length: 20, minUniqueChars: 12, maxRepeated: 2),
        );
        expect(password.split('').toSet().length, greaterThanOrEqualTo(12));
        var runLength = 1;
        for (var i = 1; i < password.length; i++) {
          if (password[i] == password[i - 1]) {
            runLength++;
            expect(runLength, lessThanOrEqualTo(2));
          } else {
            runLength = 1;
          }
        }
      }
    });
  });

  group('PassphraseGenerator', () {
    test('joins the configured word count', () {
      for (var run = 0; run < 50; run++) {
        final passphrase = CredentialGenerator.generatePassphrase(
          const PassphraseConfig(wordCount: 8),
        );
        expect(passphrase.split('-').length, 8);
      }
    });

    test('capitalizes words and appends number/symbol when asked', () {
      for (var run = 0; run < 50; run++) {
        final passphrase = CredentialGenerator.generatePassphrase(
          const PassphraseConfig(
            wordCount: 5,
            capitalize: true,
            includeNumber: true,
            includeSymbol: true,
          ),
        );
        final tokens = passphrase.split('-');
        final words = tokens.where((t) => t.contains(RegExp('[A-Za-z]')));
        expect(words.length, 5);
        for (final word in words) {
          if (word.startsWith(RegExp('[A-Za-z]'))) {
            expect(word[0], matches(RegExp('[A-Z]')));
          }
        }
        expect(passphrase.contains(RegExp('[0-9]')), isTrue);
      }
    });
  });

  group('PinGenerator', () {
    test('respects length and digit constraints', () {
      for (var run = 0; run < 100; run++) {
        final pin = CredentialGenerator.generatePin(
          const PinConfig(length: 8, avoidRepeated: true, avoidSequential: true),
        );
        expect(pin.length, 8);
        expect(pin, matches(RegExp(r'^[0-9]+$')));
        for (var i = 1; i < pin.length; i++) {
          final gap = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
          expect(gap.abs(), isNot(1));
          expect(pin[i] == pin[i - 1], isFalse);
        }
      }
    });
  });

  group('UuidGenerator', () {
    test('returns well-formed v4 UUIDs', () {
      final uuid = CredentialGenerator.generateUuidV4();
      expect(
        uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}