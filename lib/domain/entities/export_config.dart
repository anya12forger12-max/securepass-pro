import 'package:securepass_pro/domain/enums/export_format.dart';

class ExportConfig {
  const ExportConfig({
    required this.format,
    this.includeMetadata = true,
    this.maskValues = false,
    this.encrypt = false,
    this.encryptPassword = '',
    this.compress = false,
    this.includeHistory = false,
    this.includeFavorites = false,
    this.includeVault = false,
    this.includeRecipes = false,
    this.includePolicies = false,
    this.includeSettings = false,
    this.workspaceId,
    this.tags = const [],
    this.dateFrom,
    this.dateTo,
  });

  final ExportFormat format;
  final bool includeMetadata;
  final bool maskValues;
  final bool encrypt;
  final String encryptPassword;
  final bool compress;
  final bool includeHistory;
  final bool includeFavorites;
  final bool includeVault;
  final bool includeRecipes;
  final bool includePolicies;
  final bool includeSettings;
  final String? workspaceId;
  final List<String> tags;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  ExportConfig copyWith({
    ExportFormat? format,
    bool? includeMetadata,
    bool? maskValues,
    bool? encrypt,
    String? encryptPassword,
    bool? compress,
    bool? includeHistory,
    bool? includeFavorites,
    bool? includeVault,
    bool? includeRecipes,
    bool? includePolicies,
    bool? includeSettings,
    String? workspaceId,
    List<String>? tags,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearWorkspaceId = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return ExportConfig(
      format: format ?? this.format,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      maskValues: maskValues ?? this.maskValues,
      encrypt: encrypt ?? this.encrypt,
      encryptPassword: encryptPassword ?? this.encryptPassword,
      compress: compress ?? this.compress,
      includeHistory: includeHistory ?? this.includeHistory,
      includeFavorites: includeFavorites ?? this.includeFavorites,
      includeVault: includeVault ?? this.includeVault,
      includeRecipes: includeRecipes ?? this.includeRecipes,
      includePolicies: includePolicies ?? this.includePolicies,
      includeSettings: includeSettings ?? this.includeSettings,
      workspaceId: clearWorkspaceId ? null : (workspaceId ?? this.workspaceId),
      tags: tags ?? this.tags,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}
