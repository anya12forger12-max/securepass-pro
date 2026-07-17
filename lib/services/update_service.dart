import 'dart:convert';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    this.latestVersion,
    this.isUpdateAvailable = false,
    this.releaseNotes,
    this.downloadUrl,
  });

  final String currentVersion;
  final String? latestVersion;
  final bool isUpdateAvailable;
  final String? releaseNotes;
  final String? downloadUrl;
}

class UpdateHistoryEntry {
  const UpdateHistoryEntry({
    required this.version,
    required this.installedAt,
    this.changelog,
  });

  final String version;
  final DateTime installedAt;
  final String? changelog;
}

class UpdateSettings {
  const UpdateSettings({
    this.checkAutomatically = false,
    this.includePreReleases = false,
  });

  final bool checkAutomatically;
  final bool includePreReleases;
}

class UpdateService {
  UpdateService._();
  static final UpdateService _instance = UpdateService._();
  static UpdateService get instance => _instance;

  bool _initialized = false;
  UpdateSettings _settings = const UpdateSettings();
  final List<UpdateHistoryEntry> _history = [];
  static const String _settingsKey = 'update_settings';
  static const String _historyKey = 'update_history';

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadData();
    _initialized = true;
    AppLogger.instance.info('Update service initialized', category: 'UPDATE');
  }

  Future<void> _loadData() async {
    final settingsJson = PreferencesStorage.instance.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final map = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = UpdateSettings(
          checkAutomatically: map['checkAutomatically'] as bool? ?? false,
          includePreReleases: map['includePreReleases'] as bool? ?? false,
        );
      } catch (_) {}
    }

    final historyJson = PreferencesStorage.instance.getString(_historyKey);
    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          _history.add(UpdateHistoryEntry(
            version: map['version'] as String,
            installedAt: DateTime.parse(map['installedAt'] as String),
            changelog: map['changelog'] as String?,
          ));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    await PreferencesStorage.instance.setString(_settingsKey, jsonEncode({
      'checkAutomatically': _settings.checkAutomatically,
      'includePreReleases': _settings.includePreReleases,
    }));

    final historyData = _history.map((e) => {
      'version': e.version,
      'installedAt': e.installedAt.toIso8601String(),
      'changelog': e.changelog,
    }).toList();
    await PreferencesStorage.instance.setString(_historyKey, jsonEncode(historyData));
  }

  Future<UpdateInfo> checkForUpdates() async {
    final currentVersion = getCurrentVersion();
    AppLogger.instance.debug('Checking for updates (current: $currentVersion)', category: 'UPDATE');

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      isUpdateAvailable: false,
      releaseNotes: null,
      downloadUrl: null,
    );
  }

  String getCurrentVersion() => AppConstants.appVersion;

  List<UpdateHistoryEntry> getUpdateHistory() => List.unmodifiable(_history);

  UpdateSettings getUpdateSettings() => _settings;

  Future<void> configureUpdateSettings(UpdateSettings settings) async {
    _settings = settings;
    await _saveData();
    AppLogger.instance.info('Update settings configured', category: 'UPDATE');
  }

  Future<void> recordInstallation(String version, {String? changelog}) async {
    _history.insert(0, UpdateHistoryEntry(
      version: version,
      installedAt: DateTime.now(),
      changelog: changelog,
    ));
    await _saveData();
    AppLogger.instance.info('Update recorded: $version', category: 'UPDATE');
  }
}
