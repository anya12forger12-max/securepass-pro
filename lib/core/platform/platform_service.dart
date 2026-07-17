import 'dart:io' as io;

import 'package:flutter/foundation.dart';

enum AppPlatform {
  windows('Windows'),
  linux('Linux'),
  macOS('macOS'),
  android('Android'),
  iOS('iOS'),
  web('Web');

  const AppPlatform(this.displayName);
  final String displayName;

  bool get isDesktop =>
      this == AppPlatform.windows ||
      this == AppPlatform.linux ||
      this == AppPlatform.macOS;

  bool get isMobile =>
      this == AppPlatform.android ||
      this == AppPlatform.iOS;

  bool get isDesktopOS => isDesktop;

  bool get isMobileOS => isMobile;
}

class PlatformService {
  PlatformService._();

  static final PlatformService _instance = PlatformService._();
  static PlatformService get instance => _instance;

  AppPlatform? _cachedPlatform;

  AppPlatform get currentPlatform => _cachedPlatform ??= _detectPlatform();

  bool get isDesktop => currentPlatform.isDesktop;

  bool get isMobile => currentPlatform.isMobile;

  bool get isWeb => kIsWeb;

  bool get isDesktopOS => currentPlatform.isDesktopOS;

  bool get isMobileOS => currentPlatform.isMobileOS;

  bool get isLinux => currentPlatform == AppPlatform.linux;

  bool get isWindows => currentPlatform == AppPlatform.windows;

  bool get isMacOS => currentPlatform == AppPlatform.macOS;

  bool get isAndroid => currentPlatform == AppPlatform.android;

  bool get isIOS => currentPlatform == AppPlatform.iOS;

  String get platformName => currentPlatform.displayName;

  String get osVersion {
    if (kIsWeb) return 'N/A';
    return io.Platform.operatingSystemVersion;
  }

  String get locale {
    if (kIsWeb) return 'en';
    return io.Platform.localeName;
  }

  bool get supportsBiometrics => isMobile || isDesktop;

  bool get supportsSecureStorage => true;

  bool get supportsClipboard => true;

  bool get supportsNotifications => true;

  bool get supportsFilePicker => !kIsWeb || isDesktop;

  int get processorCount {
    if (kIsWeb) return 1;
    return io.Platform.numberOfProcessors;
  }

  AppPlatform _detectPlatform() {
    if (kIsWeb) return AppPlatform.web;
    if (io.Platform.isWindows) return AppPlatform.windows;
    if (io.Platform.isLinux) return AppPlatform.linux;
    if (io.Platform.isMacOS) return AppPlatform.macOS;
    if (io.Platform.isAndroid) return AppPlatform.android;
    if (io.Platform.isIOS) return AppPlatform.iOS;
    return AppPlatform.web;
  }

  Map<String, String> get debugInfo => {
        'platform': platformName,
        'os': currentPlatform.displayName,
        'osVersion': osVersion,
        'isWeb': isWeb.toString(),
        'isDesktop': isDesktop.toString(),
        'isMobile': isMobile.toString(),
        'processors': processorCount.toString(),
      };
}
