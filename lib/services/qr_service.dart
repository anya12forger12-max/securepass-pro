import 'package:securepass_pro/domain/entities/qr_data.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class QrService {
  QrService._();
  static final QrService _instance = QrService._();
  static QrService get instance => _instance;

  int _generatedCount = 0;
  final List<QrData> _recentQr = [];
  static const int _maxRecent = 50;

  Future<void> initialize() async {
    AppLogger.instance.info(
      'QrService initialized',
      category: 'QrService',
    );
  }

  QrData generateCredentialQr(String credential, {String title = ''}) {
    final qr = QrData(
      content: credential,
      type: QrType.credential,
      title: title.isNotEmpty ? title : 'Credential',
    );

    _trackGeneration(qr);

    AppLogger.instance.debug(
      'Generated credential QR: ${qr.title}',
      category: 'QrService',
    );

    return qr;
  }

  QrData generateWifiQr(
    String ssid,
    String password, {
    String security = 'WPA',
  }) {
    final escapedSsid = ssid.replaceAll('\\', '\\\\').replaceAll(';', '\\;');
    final escapedPassword =
        password.replaceAll('\\', '\\\\').replaceAll(';', '\\;');
    final content = 'WIFI:T:$security;S:$escapedSsid;P:$escapedPassword;;';

    final qr = QrData(
      content: content,
      type: QrType.wifi,
      title: ssid,
      metadata: {
        'ssid': ssid,
        'security': security,
      },
    );

    _trackGeneration(qr);

    AppLogger.instance.debug(
      'Generated WiFi QR for: $ssid',
      category: 'QrService',
    );

    return qr;
  }

  QrData generateRecoveryCodeQr(String code, {String label = ''}) {
    final qr = QrData(
      content: code,
      type: QrType.recoveryCode,
      title: label.isNotEmpty ? label : 'Recovery Code',
    );

    _trackGeneration(qr);

    AppLogger.instance.debug(
      'Generated recovery code QR: ${qr.title}',
      category: 'QrService',
    );

    return qr;
  }

  QrData generateCustomQr(
    String content, {
    String title = '',
    Map<String, dynamic>? metadata,
  }) {
    final qr = QrData(
      content: content,
      type: QrType.custom,
      title: title.isNotEmpty ? title : 'Custom QR',
      metadata: metadata ?? const {},
    );

    _trackGeneration(qr);

    AppLogger.instance.debug(
      'Generated custom QR: ${qr.title}',
      category: 'QrService',
    );

    return qr;
  }

  QrData generateWithExpiry(
    String content, {
    Duration expiry = const Duration(hours: 24),
    QrType type = QrType.custom,
    String title = '',
  }) {
    final qr = QrData(
      content: content,
      type: type,
      title: title.isNotEmpty ? title : 'Expiring QR',
      expiresAt: DateTime.now().add(expiry),
    );

    _trackGeneration(qr);

    AppLogger.instance.debug(
      'Generated expiring QR: ${qr.title}, expires in ${expiry.inMinutes}min',
      category: 'QrService',
    );

    return qr;
  }

  bool validateQrContent(String content, QrType type) {
    if (content.isEmpty) return false;

    switch (type) {
      case QrType.credential:
        return content.length <= 2048;
      case QrType.wifi:
        return content.startsWith('WIFI:');
      case QrType.recoveryCode:
        return content.length >= 4 && content.length <= 512;
      case QrType.custom:
        return content.length <= 4096;
    }
  }

  List<QrData> getRecentQr({int limit = 10}) {
    final effectiveLimit = limit.clamp(0, _recentQr.length);
    return List.unmodifiable(_recentQr.reversed.take(effectiveLimit));
  }

  void clearRecent() {
    _recentQr.clear();
    AppLogger.instance.debug(
      'Cleared recent QR data',
      category: 'QrService',
    );
  }

  Map<String, int> getStats() {
    final typeBreakdown = <String, int>{};
    for (final qr in _recentQr) {
      final typeName = qr.type.name;
      typeBreakdown[typeName] = (typeBreakdown[typeName] ?? 0) + 1;
    }

    return {
      'generated': _generatedCount,
      ...typeBreakdown,
    };
  }

  void _trackGeneration(QrData qr) {
    _generatedCount++;
    _recentQr.add(qr);

    while (_recentQr.length > _maxRecent) {
      _recentQr.removeAt(0);
    }
  }
}
