import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ensures Google UMP (GDPR) consent is collected before ads are served.
///
/// Never throws: on any platform/plugin error it falls back to allowing ads,
/// preserving existing ad-serving behavior and keeping widget tests a no-op.
class AdConsentService {
  AdConsentService._();

  static final AdConsentService instance = AdConsentService._();

  bool _finished = false;
  bool _cached = true;
  Future<bool>? _pending;

  /// Returns true when ads may be served, false when consent is missing.
  ///
  /// Concurrent callers share a single in-flight consent flow and the
  /// completed result is reused for the process lifetime.
  Future<bool> ensureConsent() {
    final pending = _pending;
    if (pending != null) {
      return pending;
    }
    if (_finished) {
      return Future<bool>.value(_cached);
    }
    final completer = Completer<bool>();
    final future = completer.future;
    _pending = future;
    _run().then(
      (value) {
        _cached = value;
        _finished = true;
        _pending = null;
        completer.complete(value);
      },
      onError: (Object error) {
        debugPrint('AdConsentService: consent flow failed: $error');
        _cached = true;
        _finished = true;
        _pending = null;
        completer.complete(true);
      },
    );
    return future;
  }

  Future<bool> _run() async {
    try {
      if (kIsWeb) {
        return true;
      }
      if (!Platform.isAndroid && !Platform.isIOS) {
        return true;
      }

      final updateCompleter = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        updateCompleter.complete,
        updateCompleter.completeError,
      );
      await updateCompleter.future;

      final ConsentInformation consent = ConsentInformation.instance;
      final status = await consent.getConsentStatus();
      if (status == ConsentStatus.required &&
          await consent.isConsentFormAvailable()) {
        final formCompleter = Completer<void>();
        ConsentForm.loadConsentForm(
          (ConsentForm form) {
            form.show(formCompleter.complete);
          },
          formCompleter.completeError,
        );
        await formCompleter.future;
      }

      return await consent.canRequestAds();
    } catch (error, stackTrace) {
      debugPrint('AdConsentService: consent flow failed: $error\n$stackTrace');
      return true;
    }
  }
}