import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/clipboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deadlineKey = 'clipboard_auto_clear_deadline';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': 'residual-secret'};
      }
      return null;
    });
    await PreferencesStorage.instance.init();
    await EnhancedClipboardService.instance.initialize();
  });

  test('an overdue deadline from a killed process is cleared on startup',
      () async {
    // A previous session copied a secret and was killed before its in-memory
    // timer could fire, leaving the deadline already in the past.
    await PreferencesStorage.instance.setString(
      _deadlineKey,
      DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
    );

    final cleared = await EnhancedClipboardService.instance
        .clearStaleClipboardOnStartup();

    expect(cleared, isTrue, reason: 'the leftover secret must be wiped');
    expect(PreferencesStorage.instance.getString(_deadlineKey), isNull,
        reason: 'a consumed deadline must not fire again');
  });

  test('a deadline still in the future is not cleared early', () async {
    await PreferencesStorage.instance.setString(
      _deadlineKey,
      DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    );

    final cleared = await EnhancedClipboardService.instance
        .clearStaleClipboardOnStartup();

    expect(cleared, isFalse, reason: 'a live deadline must not be cut short');
  });

  test('an unparseable deadline is discarded without throwing', () async {
    await PreferencesStorage.instance.setString(_deadlineKey, 'not-a-date');

    final cleared = await EnhancedClipboardService.instance
        .clearStaleClipboardOnStartup();

    expect(cleared, isFalse);
    expect(PreferencesStorage.instance.getString(_deadlineKey), isNull);
  });

  test('no persisted deadline means nothing to clear', () async {
    final cleared = await EnhancedClipboardService.instance
        .clearStaleClipboardOnStartup();
    expect(cleared, isFalse);
  });

  test('copying a secret persists a clear deadline', () async {
    final copied = await EnhancedClipboardService.instance.copy('s3cret');

    expect(copied, isTrue);
    final stored = PreferencesStorage.instance.getString(_deadlineKey);
    expect(stored, isNotNull,
        reason: 'the auto-clear deadline must outlive the process');
    expect(DateTime.parse(stored!).isAfter(DateTime.now()), isTrue);
  });

  test('repeated copies refresh the deadline rather than leaving a stale one',
      () async {
    await EnhancedClipboardService.instance.copy('first');
    final first = PreferencesStorage.instance.getString(_deadlineKey);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await EnhancedClipboardService.instance.copy('second');
    final second = PreferencesStorage.instance.getString(_deadlineKey);

    expect(second, isNotNull);
    expect(DateTime.parse(second!).isAfter(DateTime.parse(first!)), isTrue,
        reason: 'each copy must own its own auto-clear window');
  });

  test('a manual clear removes the persisted deadline', () async {
    await EnhancedClipboardService.instance.copy('s3cret');
    expect(PreferencesStorage.instance.getString(_deadlineKey), isNotNull);

    await EnhancedClipboardService.instance.clear();

    expect(PreferencesStorage.instance.getString(_deadlineKey), isNull);
  });
}
