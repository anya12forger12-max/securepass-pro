enum SearchCategory { all, vault, history, settings, commands, documentation, developer, accessibility }

class SearchableItem {
  const SearchableItem({
    required this.id,
    required this.title,
    required this.category,
    this.subtitle = '',
    this.keywords = const [],
    this.route = '',
    this.score = 1.0,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final SearchCategory category;
  final String subtitle;
  final List<String> keywords;
  final String route;
  final double score;
  final Map<String, dynamic> metadata;
}

class SearchFilter {
  const SearchFilter({this.categories, this.minScore = 0, this.limit = 50});
  final Set<SearchCategory>? categories;
  final double minScore;
  final int limit;
}

class SearchResult {
  const SearchResult({required this.items, required this.query, required this.durationMs});
  final List<SearchableItem> items;
  final String query;
  final double durationMs;
}

class SearchSuggestion {
  const SearchSuggestion({required this.text, required this.category, this.score = 0});
  final String text;
  final SearchCategory category;
  final double score;
}

class SearchEngine {
  SearchEngine._();
  static final SearchEngine instance = SearchEngine._();

  final Map<String, SearchableItem> _index = {};
  final List<String> _searchHistory = [];
  int _maxHistory = 100;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void indexItem(SearchableItem item) {
    _index[item.id] = item;
  }

  void indexAll(List<SearchableItem> items) {
    for (final item in items) {
      _index[item.id] = item;
    }
  }

  void removeItem(String id) {
    _index.remove(id);
  }

  void reindex() {
    // Rebuild internal index if needed
  }

  SearchResult search(String query, {SearchFilter? filter}) {
    final sw = Stopwatch()..start();
    final lowerQuery = query.toLowerCase();
    final results = <SearchableItem>[];

    for (final item in _index.values) {
      final relevance = _calculateRelevance(item, lowerQuery);
      if (relevance > 0) {
        results.add(SearchableItem(
          id: item.id,
          title: item.title,
          category: item.category,
          subtitle: item.subtitle,
          keywords: item.keywords,
          route: item.route,
          score: relevance * item.score,
          metadata: item.metadata,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    var filtered = results.where((r) => r.score >= (filter?.minScore ?? 0)).toList();
    if (filter?.categories != null) {
      filtered = filtered.where((r) => filter!.categories!.contains(r.category)).toList();
    }
    final limit = filter?.limit ?? 50;
    if (filtered.length > limit) filtered = filtered.sublist(0, limit);

    sw.stop();
    _recordHistory(query);
    return SearchResult(items: filtered, query: query, durationMs: sw.elapsedMicroseconds / 1000.0);
  }

  double _calculateRelevance(SearchableItem item, String lowerQuery) {
    if (lowerQuery.isEmpty) return 1.0;
    if (item.title.toLowerCase().contains(lowerQuery)) return 1.0;
    if (item.subtitle.toLowerCase().contains(lowerQuery)) return 0.8;
    for (final keyword in item.keywords) {
      if (keyword.toLowerCase().contains(lowerQuery)) return 0.6;
    }
    // Tokenized matching
    final queryTokens = lowerQuery.split(' ');
    var matchCount = 0;
    for (final token in queryTokens) {
      if (item.title.toLowerCase().contains(token)) matchCount++;
      for (final keyword in item.keywords) {
        if (keyword.toLowerCase().contains(token)) { matchCount++; break; }
      }
    }
    return matchCount > 0 ? matchCount / queryTokens.length * 0.5 : 0;
  }

  List<SearchSuggestion> getSuggestions(String partial, {int limit = 10}) {
    if (partial.isEmpty) return [];
    final lower = partial.toLowerCase();
    final suggestions = <SearchSuggestion>[];
    final seen = <String>{};
    for (final item in _index.values) {
      if (item.title.toLowerCase().startsWith(lower) && !seen.contains(item.title)) {
        seen.add(item.title);
        suggestions.add(SearchSuggestion(text: item.title, category: item.category, score: 1.0));
        if (suggestions.length >= limit) break;
      }
    }
    if (suggestions.length < limit) {
      for (final item in _index.values) {
        if (item.title.toLowerCase().contains(lower) && !seen.contains(item.title)) {
          seen.add(item.title);
          suggestions.add(SearchSuggestion(text: item.title, category: item.category, score: 0.5));
          if (suggestions.length >= limit) break;
        }
      }
    }
    return suggestions;
  }

  List<String> getSynonyms(String term) {
    // Placeholder for synonym expansion
    return [term];
  }

  void _recordHistory(String query) {
    _searchHistory.add(query);
    if (_searchHistory.length > _maxHistory) _searchHistory.removeAt(0);
  }

  List<String> getSearchHistory() => List.unmodifiable(_searchHistory);
  int get indexSize => _index.length;

  Map<String, dynamic> getDiagnostics() {
    final byCategory = <String, int>{};
    for (final cat in SearchCategory.values) {
      byCategory[cat.name] = _index.values.where((i) => i.category == cat).length;
    }
    return {
      'indexSize': _index.length,
      'searchHistorySize': _searchHistory.length,
      'itemsByCategory': byCategory,
    };
  }
}
