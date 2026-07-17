import 'package:flutter/material.dart';

enum SearchResultType { navigation, setting, command, documentation, help }

class SearchResult {
  const SearchResult({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.icon,
    this.route,
    this.score = 0.0,
  });

  final String id;
  final String title;
  final SearchResultType type;
  final String? subtitle;
  final IconData? icon;
  final String? route;
  final double score;
}
