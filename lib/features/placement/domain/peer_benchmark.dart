/// Placeholder "norm" data for the peer-comparison tracker. There's no real
/// aggregate data across users yet, so percentiles are computed against this
/// hardcoded age-banded average rather than actual peer scores. Swap this
/// table out for a real norm (or live aggregate query) once there's enough
/// usage to compute one.
class PeerBenchmark {
  static const List<(int maxAge, double average)> _bands = [
    (4, 4.0),
    (6, 5.5),
    (8, 7.0),
    (99, 8.0),
  ];

  static double _averageForAge(int age) {
    for (final band in _bands) {
      if (age <= band.$1) return band.$2;
    }
    return _bands.last.$2;
  }

  /// Rough percentile (1–99) for a 0–10 [score] at [age], centered on the
  /// age band's placeholder average. Not a real statistical norm.
  static int percentile({required num score, required int age}) {
    final average = _averageForAge(age);
    final raw = 50 + (score - average) * 15;
    return raw.round().clamp(1, 99);
  }
}
