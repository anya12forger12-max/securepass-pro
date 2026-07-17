import 'package:securepass_pro/domain/enums/generator_type.dart';

enum FilterDateRange { today, thisWeek, thisMonth, thisYear, custom }

class SearchFilter {
  const SearchFilter({
    this.query = '',
    this.generatorTypes = const {},
    this.tags = const {},
    this.workspaceId,
    this.dateRange,
    this.dateFrom,
    this.dateTo,
    this.minEntropy,
    this.maxEntropy,
    this.minLength,
    this.maxLength,
    this.favoritesOnly = false,
    this.includeHistory = true,
    this.includeVault = true,
    this.includeRecipes = true,
  });

  final String query;
  final Set<GeneratorType> generatorTypes;
  final Set<String> tags;
  final String? workspaceId;
  final FilterDateRange? dateRange;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minEntropy;
  final double? maxEntropy;
  final int? minLength;
  final int? maxLength;
  final bool favoritesOnly;
  final bool includeHistory;
  final bool includeVault;
  final bool includeRecipes;

  bool get hasFilters =>
      query.isNotEmpty ||
      generatorTypes.isNotEmpty ||
      tags.isNotEmpty ||
      workspaceId != null ||
      dateRange != null ||
      favoritesOnly;

  SearchFilter copyWith({
    String? query,
    Set<GeneratorType>? generatorTypes,
    Set<String>? tags,
    String? workspaceId,
    FilterDateRange? dateRange,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minEntropy,
    double? maxEntropy,
    int? minLength,
    int? maxLength,
    bool? favoritesOnly,
    bool? includeHistory,
    bool? includeVault,
    bool? includeRecipes,
    bool clearWorkspaceId = false,
    bool clearDateRange = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearEntropy = false,
    bool clearLength = false,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      generatorTypes: generatorTypes ?? this.generatorTypes,
      tags: tags ?? this.tags,
      workspaceId: clearWorkspaceId ? null : (workspaceId ?? this.workspaceId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      minEntropy: clearEntropy ? null : (minEntropy ?? this.minEntropy),
      maxEntropy: clearEntropy ? null : (maxEntropy ?? this.maxEntropy),
      minLength: clearLength ? null : (minLength ?? this.minLength),
      maxLength: clearLength ? null : (maxLength ?? this.maxLength),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      includeHistory: includeHistory ?? this.includeHistory,
      includeVault: includeVault ?? this.includeVault,
      includeRecipes: includeRecipes ?? this.includeRecipes,
    );
  }
}
