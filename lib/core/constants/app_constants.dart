abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'SecurePass Pro';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'Enterprise-grade password management and security platform';
  static const String packageName = 'com.securepass.pro';

  static const String androidPackageName = 'com.securepass.pro';
  static const String iosBundleId = 'com.securepass.pro';
  static const String webAppTitle = 'SecurePass Pro';

  static const String copyrightHolder = 'SecurePass Pro';
  static const int currentYear = 2026;

  static const String supportEmail = 'support@securepass.pro';
  static const String privacyPolicyUrl = 'https://securepass.pro/privacy';
  static const String termsOfServiceUrl = 'https://securepass.pro/terms';

  static const int maxPasswordLength = 128;
  static const int minPasswordLength = 8;
  static const int maxVaultNameLength = 64;
  static const int maxEntryNameLength = 128;
  static const int maxNotesLength = 4096;
  static const int maxCustomFieldCount = 16;
  static const int maxAttachmentSizeBytes = 10 * 1024 * 1024;
  static const int maxVaultEntries = 10000;
  static const int sessionTimeoutMinutes = 15;
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const int passwordHistoryCount = 20;
  static const int autoLockTimeoutSeconds = 300;
}
