enum ApiClassification { stable, experimental, deprecated, internal, future }

class ApiEntry {
  const ApiEntry({
    required this.name,
    required this.classification,
    this.description = '',
    this.since = '1.0.0',
    this.deprecatedIn,
    this.removalVersion,
    this.category = '',
  });

  final String name;
  final ApiClassification classification;
  final String description;
  final String since;
  final String? deprecatedIn;
  final String? removalVersion;
  final String category;
}

class ApiMaturity {
  ApiMaturity._();
  static final ApiMaturity instance = ApiMaturity._();

  final Map<String, ApiEntry> _apis = {};

  void register(ApiEntry api) {
    _apis[api.name] = api;
  }

  void unregister(String apiName) {
    _apis.remove(apiName);
  }

  ApiEntry? getApi(String apiName) => _apis[apiName];
  List<ApiEntry> getAllApis() => List.unmodifiable(_apis.values);

  List<ApiEntry> getApisByClassification(ApiClassification classification) {
    return _apis.values.where((a) => a.classification == classification).toList();
  }

  List<ApiEntry> getStableApis() => getApisByClassification(ApiClassification.stable);
  List<ApiEntry> getExperimentalApis() => getApisByClassification(ApiClassification.experimental);
  List<ApiEntry> getDeprecatedApis() => getApisByClassification(ApiClassification.deprecated);
  List<ApiEntry> getInternalApis() => getApisByClassification(ApiClassification.internal);
  List<ApiEntry> getFutureApis() => getApisByClassification(ApiClassification.future);

  void initializeDefaults() {
    const defaultApis = [
      ApiEntry(name: 'ICredentialProvider', classification: ApiClassification.stable, category: 'extension', description: 'Credential provider interface'),
      ApiEntry(name: 'IPasswordAnalysisProvider', classification: ApiClassification.stable, category: 'extension', description: 'Password analysis interface'),
      ApiEntry(name: 'IPolicyProvider', classification: ApiClassification.stable, category: 'extension', description: 'Policy engine interface'),
      ApiEntry(name: 'IThemeProvider', classification: ApiClassification.stable, category: 'extension', description: 'Theme provider interface'),
      ApiEntry(name: 'IAccessibilityProvider', classification: ApiClassification.stable, category: 'extension', description: 'Accessibility provider interface'),
      ApiEntry(name: 'IExportProvider', classification: ApiClassification.stable, category: 'extension', description: 'Export provider interface'),
      ApiEntry(name: 'IImportProvider', classification: ApiClassification.stable, category: 'extension', description: 'Import provider interface'),
      ApiEntry(name: 'INotificationProvider', classification: ApiClassification.stable, category: 'extension', description: 'Notification provider interface'),
      ApiEntry(name: 'IDeveloperToolProvider', classification: ApiClassification.experimental, category: 'extension', description: 'Developer tool interface'),
      ApiEntry(name: 'IEnterpriseModule', classification: ApiClassification.experimental, category: 'extension', description: 'Enterprise module interface'),
      ApiEntry(name: 'IFutureIntegration', classification: ApiClassification.future, category: 'extension', description: 'Future integration interface'),
      ApiEntry(name: 'EventBus', classification: ApiClassification.stable, category: 'infrastructure', description: 'Event bus system'),
      ApiEntry(name: 'AdvancedEventBus', classification: ApiClassification.stable, category: 'infrastructure', description: 'Advanced event bus with async/cancelable events'),
      ApiEntry(name: 'TaskEngine', classification: ApiClassification.stable, category: 'infrastructure', description: 'Background task execution engine'),
      ApiEntry(name: 'CacheSystem', classification: ApiClassification.stable, category: 'infrastructure', description: 'Cache management system'),
      ApiEntry(name: 'SearchEngine', classification: ApiClassification.stable, category: 'infrastructure', description: 'Search platform'),
      ApiEntry(name: 'CommandEngine', classification: ApiClassification.stable, category: 'infrastructure', description: 'Command execution platform'),
      ApiEntry(name: 'CompositionEngine', classification: ApiClassification.stable, category: 'infrastructure', description: 'Feature composition engine'),
      ApiEntry(name: 'ModuleRegistry', classification: ApiClassification.stable, category: 'infrastructure', description: 'Module registration and lifecycle'),
      ApiEntry(name: 'ServiceRegistry', classification: ApiClassification.stable, category: 'infrastructure', description: 'Service registration and lifecycle'),
    ];
    for (final api in defaultApis) {
      register(api);
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalApis': _apis.length,
      'byClassification': {
        for (final c in ApiClassification.values)
          c.name: getApisByClassification(c).length,
      },
    };
  }
}
