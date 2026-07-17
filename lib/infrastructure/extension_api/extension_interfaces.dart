import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';

enum ApiStability { stable, experimental, deprecated, internal, public }

class ApiMetadata {
  const ApiMetadata({
    required this.name,
    required this.version,
    this.stability = ApiStability.public,
    this.description = '',
    this.since = '1.0.0',
    this.deprecatedIn,
    this.removalVersion,
  });

  final String name;
  final SemanticVersion version;
  final ApiStability stability;
  final String description;
  final String since;
  final String? deprecatedIn;
  final String? removalVersion;

  bool get isStable => stability == ApiStability.stable;
  bool get isDeprecated => stability == ApiStability.deprecated;
  bool get isExperimental => stability == ApiStability.experimental;
}

abstract class ICredentialProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getCredentials({String? workspaceId});
  Future<Map<String, dynamic>?> getCredentialById(String id);
  Future<bool> validateCredential(Map<String, dynamic> credential);
}

abstract class ICredentialValidator {
  ApiMetadata get apiMetadata;
  Future<bool> validate(String credential, {Map<String, dynamic>? rules});
  Future<List<String>> getValidationErrors(String credential, {Map<String, dynamic>? rules});
}

abstract class IPasswordAnalysisProvider {
  ApiMetadata get apiMetadata;
  Future<Map<String, dynamic>> analyze(String password);
  Future<double> calculateEntropy(String password);
  Future<List<String>> getRecommendations(String password);
}

abstract class IEntropyAnalysisProvider {
  ApiMetadata get apiMetadata;
  Future<double> calculateEntropy(String value, {String? charset});
  Future<Map<String, dynamic>> analyzeEntropy(String value);
}

abstract class IPolicyProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getPolicies();
  Future<Map<String, dynamic>?> getPolicyById(String id);
  Future<bool> validateAgainstPolicy(String credential, String policyId);
}

abstract class IRecipeProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getRecipes();
  Future<Map<String, dynamic>?> getRecipeById(String id);
}

abstract class IWorkspaceProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getWorkspaces();
  Future<Map<String, dynamic>?> getWorkspaceById(String id);
}

abstract class IDashboardWidgetProvider {
  ApiMetadata get apiMetadata;
  String get widgetId;
  String get widgetTitle;
  Future<Map<String, dynamic>> getData();
}

abstract class IThemeProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getThemes();
  Future<Map<String, dynamic>?> getThemeById(String id);
}

abstract class IAccessibilityProvider {
  ApiMetadata get apiMetadata;
  Future<List<Map<String, dynamic>>> getProfiles();
  Future<Map<String, dynamic>?> getProfileById(String id);
}

abstract class IExportProvider {
  ApiMetadata get apiMetadata;
  Future<String> export(Map<String, dynamic> data, String format);
  Future<List<String>> getSupportedFormats();
}

abstract class IImportProvider {
  ApiMetadata get apiMetadata;
  Future<Map<String, dynamic>> import(String data, String format);
  Future<List<String>> getSupportedFormats();
}

abstract class INotificationProvider {
  ApiMetadata get apiMetadata;
  Future<void> sendNotification(String title, String message, {String? priority});
}

abstract class IDeveloperToolProvider {
  ApiMetadata get apiMetadata;
  String get toolId;
  String get toolName;
  Future<void> execute(Map<String, dynamic> params);
}

abstract class IEnterpriseModule {
  ApiMetadata get apiMetadata;
  Future<void> initialize(Map<String, dynamic> config);
  Future<void> shutdown();
  Future<Map<String, dynamic>> getStatus();
}

abstract class IFutureIntegration {
  ApiMetadata get apiMetadata;
  bool get isAvailable;
  Future<void> connect(Map<String, dynamic> config);
  Future<void> disconnect();
}
