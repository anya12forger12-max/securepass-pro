import 'dart:async';

import 'package:flutter/services.dart';

class ClipboardService {
  ClipboardService._({
    Duration? defaultAutoClearDuration,
  }) : _defaultAutoClearDuration =
            defaultAutoClearDuration ?? const Duration(seconds: 30);

  static ClipboardService? _instance;

  factory ClipboardService({
    Duration? defaultAutoClearDuration,
  }) {
    _instance ??= ClipboardService._(
      defaultAutoClearDuration: defaultAutoClearDuration,
    );
    return _instance!;
  }

  final Duration _defaultAutoClearDuration;
  Timer? _autoClearTimer;
  bool _hasActiveContent = false;

  bool get hasActiveContent => _hasActiveContent;

  Future<bool> copyToClipboard(
    String text, {
    Duration? autoClearDuration,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _hasActiveContent = true;
      _scheduleAutoClear(autoClearDuration ?? _defaultAutoClearDuration);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getClipboardContent() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null;
    }
  }

  Future<bool> clearClipboard() async {
    try {
      _autoClearTimer?.cancel();
      _autoClearTimer = null;
      await Clipboard.setData(const ClipboardData(text: ''));
      _hasActiveContent = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _scheduleAutoClear(Duration duration) {
    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(duration, clearClipboard);
  }

  void cancelAutoClear() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
  }

  void dispose() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
    _hasActiveContent = false;
    _instance = null;
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}
