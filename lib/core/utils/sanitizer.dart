abstract final class LogSanitizer {
  LogSanitizer._();

  static final RegExp _passwordPattern = RegExp(
    r'(password|passwd|pwd|pass|secret|token|api[_-]?key|auth|credential|access[_-]?key|private[_-]?key|secret[_-]?key)\s*[=:]\s*\S+',
    caseSensitive: false,
  );

  static final RegExp _bearerPattern = RegExp(r'Bearer\s+\S+', caseSensitive: false);

  static final RegExp _basicAuthPattern = RegExp(r'Basic\s+\S+', caseSensitive: false);

  static final RegExp _connectionStringPattern = RegExp(
    r'(mongodb|mysql|postgres|redis|amqp)://\S+',
    caseSensitive: false,
  );

  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _creditCardPattern = RegExp(
    r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
  );

  static final RegExp _ssnPattern = RegExp(
    r'\b\d{3}-\d{2}-\d{4}\b',
  );

  static final Set<String> _sensitiveKeys = {
    'password', 'passwd', 'pwd', 'pass', 'secret', 'token',
    'api_key', 'apikey', 'api-key', 'auth', 'credential',
    'access_key', 'accesskey', 'access-key', 'private_key',
    'privatekey', 'private-key', 'secret_key', 'secretkey',
    'secret-key', 'session', 'session_id', 'sessionid',
    'jwt', 'refresh_token', 'access_token', 'bearer',
    'encryption_key', 'signing_key',
  };

  static String sanitize(String input) {
    var result = input;

    result = result.replaceAllMapped(_passwordPattern, (match) {
      final key = match.group(1)!;
      return '$key=[REDACTED]';
    });

    result = result.replaceAllMapped(_bearerPattern, (match) {
      return 'Bearer [REDACTED]';
    });

    result = result.replaceAllMapped(_basicAuthPattern, (match) {
      return 'Basic [REDACTED]';
    });

    result = result.replaceAllMapped(_connectionStringPattern, (match) {
      final uri = Uri.tryParse(match.group(0)!);
      if (uri != null && uri.userInfo.isNotEmpty) {
        return '${uri.scheme}://[REDACTED]@${uri.host}';
      }
      return '[REDACTED]';
    });

    result = result.replaceAll(_emailPattern, '[EMAIL_REDACTED]');
    result = result.replaceAll(_creditCardPattern, '[CARD_REDACTED]');
    result = result.replaceAll(_ssnPattern, '[SSN_REDACTED]');

    return result;
  }

  static String sanitizeKeyValues(String input) {
    final buffer = StringBuffer();
    final lines = input.split('\n');

    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      final equalsIndex = line.indexOf('=');

      int separatorIndex = -1;
      if (colonIndex >= 0 && equalsIndex >= 0) {
        separatorIndex = colonIndex < equalsIndex ? colonIndex : equalsIndex;
      } else if (colonIndex >= 0) {
        separatorIndex = colonIndex;
      } else if (equalsIndex >= 0) {
        separatorIndex = equalsIndex;
      }

      if (separatorIndex >= 0) {
        final key = line.substring(0, separatorIndex).trim().toLowerCase();

        if (_sensitiveKeys.contains(key) || _isSensitiveKey(key)) {
          buffer.writeln('${line.substring(0, separatorIndex + 1)} [REDACTED]');
          continue;
        }
      }

      buffer.writeln(line);
    }

    return buffer.toString().trimRight();
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.replaceAll(RegExp(r'[-_\s]'), '').toLowerCase();
    for (final sensitive in _sensitiveKeys) {
      if (normalized.contains(sensitive.replaceAll(RegExp(r'[-_\s]'), ''))) {
        return true;
      }
    }
    return false;
  }

  static String sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (_sensitiveKeys.contains(key) || _isSensitiveKey(key)) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (entry.value is String) {
        sanitized[entry.key] = sanitize(entry.value as String);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized.toString();
  }
}
