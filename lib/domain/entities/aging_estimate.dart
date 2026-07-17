class AgingEstimate {
  const AgingEstimate({
    required this.currentBits,
    required this.currentRating,
    required this.estimatedYearsToCrack,
    required this.quantumResistance,
    required this.quantumYearsToCrack,
    required this.recommendations,
  });

  final double currentBits;
  final String currentRating;
  final String estimatedYearsToCrack;
  final String quantumResistance;
  final String quantumYearsToCrack;
  final List<String> recommendations;

  @override
  String toString() =>
      'AgingEstimate(bits: $currentBits, rating: $currentRating)';
}
