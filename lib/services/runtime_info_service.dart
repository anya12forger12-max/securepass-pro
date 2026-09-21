import 'package:package_info_plus/package_info_plus.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class RuntimeInfoService {
  RuntimeInfoService._();
  static final RuntimeInfoService _instance = RuntimeInfoService._();
  static RuntimeInfoService get instance => _instance;

  String _versionLabel = AppConstants.appVersion;

  String get versionLabel => _versionLabel;

  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final buildNumber = info.buildNumber.trim();
      if (version.isEmpty) {
        return;
      }
      _versionLabel =
          buildNumber.isEmpty ? version : '$version+$buildNumber';
      AppLogger.instance.info(
        'Runtime version resolved: $_versionLabel',
        category: 'RUNTIME',
      );
    } on Object {
      AppLogger.instance.warning(
        'Could not resolve runtime version; using compiled constant',
        category: 'RUNTIME',
      );
    }
  }
}
