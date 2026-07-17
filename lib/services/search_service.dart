import 'package:securepass_pro/domain/entities/search_result.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class SearchService {
  SearchService._();
  static final SearchService _instance = SearchService._();
  static SearchService get instance => _instance;

  bool _initialized = false;
  final Map<String, SearchResult> _index = {};

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Search service initialized with 0 items', category: 'SEARCH');
  }

  void indexItem(SearchResult item) {
    _index[item.id] = item;
    AppLogger.instance.debug('Indexed item: ${item.title} (total: ${_index.length})', category: 'SEARCH');
  }

  void removeItem(String id) {
    _index.remove(id);
  }

  List<SearchResult> search(String query) {
    if (query.isEmpty) return List.unmodifiable(_index.values);
    final lowerQuery = query.toLowerCase();
    final results = <SearchResult>[];

    for (final item in _index.values) {
      final score = _calculateScore(item, lowerQuery);
      if (score > 0) {
        results.add(SearchResult(
          id: item.id,
          title: item.title,
          type: item.type,
          subtitle: item.subtitle,
          icon: item.icon,
          route: item.route,
          score: score,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  double _calculateScore(SearchResult item, String query) {
    final titleLower = item.title.toLowerCase();
    final subtitleLower = item.subtitle?.toLowerCase() ?? '';
    double score = 0;

    if (titleLower == query) {
      score = 100;
    } else if (titleLower.startsWith(query)) {
      score = 80;
    } else if (titleLower.contains(query)) {
      score = 60;
    }

    if (subtitleLower.contains(query) && subtitleLower.isNotEmpty) {
      score += 20;
    }

    final queryWords = query.split(' ');
    for (final word in queryWords) {
      if (word.isEmpty) continue;
      if (titleLower.contains(word)) score += 10;
      if (subtitleLower.contains(word)) score += 5;
    }

    return score;
  }

  void clearIndex() {
    _index.clear();
    AppLogger.instance.info('Search index cleared', category: 'SEARCH');
  }

  int getIndexedCount() => _index.length;
}
