class ComparisonItem {
  const ComparisonItem({
    required this.label,
    required this.value1,
    required this.value2,
    this.isIdentical = false,
  });

  final String label;
  final String value1;
  final String value2;
  final bool isIdentical;
}

class ComparisonResult {
  const ComparisonResult({
    required this.items,
    required this.password1Entropy,
    required this.password2Entropy,
    required this.password1Strength,
    required this.password2Strength,
    required this.winner,
    required this.summary,
  });

  final List<ComparisonItem> items;
  final double password1Entropy;
  final double password2Entropy;
  final int password1Strength;
  final int password2Strength;
  final int winner;
  final String summary;

  @override
  String toString() =>
      'ComparisonResult(winner: $winner, summary: $summary)';
}
