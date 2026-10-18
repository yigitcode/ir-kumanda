import 'ir_signal.dart';

/// NEC infrared protocol (38 kHz, pulse-distance coding, LSB first).
///
/// An 8-bit address is sent followed by its inverse; a 16-bit ("extended")
/// address is sent low byte first with no inverse. The command byte is always
/// followed by its inverse.
class Nec {
  Nec._();

  static const int carrierHz = 38000;
  static const int _unit = 562;
  static const int _framePeriodUs = 108000;

  /// One complete key frame, padded to the 108 ms NEC frame period.
  static IrSignal frame(int address, int command) {
    final pattern = <int>[9000, 4500];
    for (final byte in _bytes(address, command)) {
      for (var bit = 0; bit < 8; bit++) {
        pattern
          ..add(_unit)
          ..add((byte >> bit) & 1 == 1 ? 3 * _unit : _unit);
      }
    }
    pattern.add(_unit);
    pattern.add(_framePeriodUs - _sum(pattern));
    return IrSignal(carrierHz, pattern);
  }

  /// [count] "key still held" repeat codes, each one frame period long.
  static IrSignal repeat([int count = 1]) {
    const one = [9000, 2250, _unit];
    final code = [...one, _framePeriodUs - _sum(one)];
    return IrSignal(carrierHz, [for (var i = 0; i < count; i++) ...code]);
  }

  static List<int> _bytes(int address, int command) {
    if (address < 0 || address > 0xFFFF) throw ArgumentError.value(address, 'address');
    if (command < 0 || command > 0xFF) throw ArgumentError.value(command, 'command');
    final addressBytes = address > 0xFF
        ? [address & 0xFF, (address >> 8) & 0xFF]
        : [address, ~address & 0xFF];
    return [...addressBytes, command, ~command & 0xFF];
  }

  static int _sum(List<int> values) => values.fold(0, (a, b) => a + b);
}
