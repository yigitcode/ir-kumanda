import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ir_kumanda/ir/ir_signal.dart';
import 'package:ir_kumanda/ir/ir_transmitter.dart';
import 'package:ir_kumanda/remote/remote_profile.dart';

/// Records every burst; takes as long as the burst would on a phone.
class FakeTransmitter implements IrTransmitter {
  FakeTransmitter({this.available = true, this.fails = false});

  final bool available;
  final bool fails;
  final sent = <IrSignal>[];

  @override
  Future<bool> hasEmitter() async => available;

  @override
  Future<void> transmit(IrSignal signal) async {
    if (fails) throw Exception('HAL error');
    sent.add(signal);
    await Future<void>.delayed(Duration(microseconds: signal.durationUs));
  }
}

RemoteProfile loadToshiba() => RemoteProfile.fromJson(
    jsonDecode(File('assets/remotes/toshiba_ct-8543.json').readAsStringSync()) as Map<String, dynamic>);

/// Decodes one NEC key frame back into its four bytes.
List<int> decodeNecFrame(List<int> p) {
  expect(p.take(2), [9000, 4500]);
  final bytes = [0, 0, 0, 0];
  for (var i = 0; i < 32; i++) {
    expect(p[2 + 2 * i], 562);
    if (p[3 + 2 * i] > 1000) bytes[i >> 3] |= 1 << (i & 7);
  }
  expect(p[66], 562);
  return bytes;
}

bool isNecRepeat(IrSignal s) => s.pattern.length >= 4 && s.pattern[0] == 9000 && s.pattern[1] == 2250;
