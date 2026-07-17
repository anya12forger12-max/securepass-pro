class PinConfig {
  const PinConfig({
    this.length = 6,
    this.avoidRepeated = false,
    this.avoidSequential = false,
  });

  final int length;
  final bool avoidRepeated;
  final bool avoidSequential;

  PinConfig copyWith({int? length, bool? avoidRepeated, bool? avoidSequential}) {
    return PinConfig(
      length: length ?? this.length,
      avoidRepeated: avoidRepeated ?? this.avoidRepeated,
      avoidSequential: avoidSequential ?? this.avoidSequential,
    );
  }
}
