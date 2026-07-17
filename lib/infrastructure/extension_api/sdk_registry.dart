import 'package:securepass_pro/infrastructure/extension_api/extension_interfaces.dart';

class SdkRegistration {
  const SdkRegistration({
    required this.id,
    required this.interfaceType,
    required this.provider,
    required this.metadata,
    this.version = '1.0.0',
  });

  final String id;
  final String interfaceType;
  final dynamic provider;
  final ApiMetadata metadata;
  final String version;
}

class SdkRegistry {
  SdkRegistry._();
  static final SdkRegistry instance = SdkRegistry._();

  final Map<String, SdkRegistration> _registrations = {};
  final Map<String, List<String>> _byInterfaceType = {};

  void register(SdkRegistration registration) {
    _registrations[registration.id] = registration;
    _byInterfaceType.putIfAbsent(registration.interfaceType, () => []).add(registration.id);
  }

  void unregister(String id) {
    final reg = _registrations.remove(id);
    if (reg != null) {
      _byInterfaceType[reg.interfaceType]?.remove(id);
    }
  }

  SdkRegistration? getRegistration(String id) => _registrations[id];

  List<SdkRegistration> getRegistrationsByType(String interfaceType) {
    final ids = _byInterfaceType[interfaceType] ?? [];
    return ids.map((id) => _registrations[id]).whereType<SdkRegistration>().toList();
  }

  List<SdkRegistration> getAllRegistrations() => List.unmodifiable(_registrations.values);

  List<SdkRegistration> getStableRegistrations() {
    return _registrations.values.where((r) => r.metadata.isStable).toList();
  }

  List<SdkRegistration> getDeprecatedRegistrations() {
    return _registrations.values.where((r) => r.metadata.isDeprecated).toList();
  }

  List<SdkRegistration> getExperimentalRegistrations() {
    return _registrations.values.where((r) => r.metadata.isExperimental).toList();
  }

  bool isRegistered(String id) => _registrations.containsKey(id);

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalRegistrations': _registrations.length,
      'registrationsByType': _byInterfaceType.map(
        (k, v) => MapEntry(k, v.length),
      ),
      'stableCount': getStableRegistrations().length,
      'deprecatedCount': getDeprecatedRegistrations().length,
      'experimentalCount': getExperimentalRegistrations().length,
      'registrations': {
        for (final entry in _registrations.entries)
          entry.key: {
            'type': entry.value.interfaceType,
            'version': entry.value.version,
            'stability': entry.value.metadata.stability.name,
          },
      },
    };
  }
}
