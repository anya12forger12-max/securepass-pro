import 'package:securepass_pro/domain/enums/generator_type.dart';

class FavoriteItem {
  FavoriteItem({
    required this.id,
    required this.value,
    required this.generatorType,
    this.label = '',
    this.metadata = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String value;
  final GeneratorType generatorType;
  final String label;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}
