import 'package:flutter_test/flutter_test.dart';
import 'package:ir_kumanda/ir/nec.dart';

import 'helpers.dart';

void main() {
  test('8-bit address frame carries address, command and their inverses', () {
    final s = Nec.frame(0x40, 0x12);
    expect(s.frequency, 38000);
    expect(decodeNecFrame(s.pattern), [0x40, 0xBF, 0x12, 0xED]);
    expect(s.pattern.length, 68);
    expect(s.durationUs, 108000);
  });

  test('16-bit address is sent low byte first without inverse', () {
    expect(decodeNecFrame(Nec.frame(0x7D02, 0x46).pattern), [0x02, 0x7D, 0x46, 0xB9]);
  });

  test('repeat codes are one frame period each', () {
    final r = Nec.repeat(3);
    expect(r.pattern.length, 12);
    expect(r.pattern.take(3), [9000, 2250, 562]);
    expect(r.durationUs, 3 * 108000);
  });

  test('rejects values outside the protocol', () {
    expect(() => Nec.frame(0x10000, 1), throwsArgumentError);
    expect(() => Nec.frame(0x40, 0x100), throwsArgumentError);
  });
}
