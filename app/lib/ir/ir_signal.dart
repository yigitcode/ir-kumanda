/// A ready-to-send infrared burst: carrier frequency plus alternating
/// on/off durations in microseconds, starting with "on".
class IrSignal {
  const IrSignal(this.frequency, this.pattern);

  final int frequency;
  final List<int> pattern;

  int get durationUs => pattern.fold(0, (a, b) => a + b);
}
