import 'package:flutter_test/flutter_test.dart';
import 'package:ir_kumanda/remote/remote_controller.dart';

import 'helpers.dart';

void main() {
  final profile = loadToshiba();

  test('Toshiba CT-8543 profile', () {
    expect(profile.address, 0x40);
    expect(profile.keys['power'], 0x12);
    expect(profile.keys['netflix'], 0x2A);
    expect(profile.keys['youtube'], 0xD2);
    expect(profile.keys['prime_video'], 0x32);
    expect(profile.keys['home'], 0x34);
    final commands = profile.keys.values.toList();
    expect(commands.toSet().length, commands.length, reason: 'two keys share a command');
  });

  Future<(RemoteController, FakeTransmitter)> ready({bool available = true, bool fails = false}) async {
    final tx = FakeTransmitter(available: available, fails: fails);
    final controller = RemoteController(profile, tx);
    await controller.init();
    return (controller, tx);
  }

  test('a tap sends exactly one frame', () async {
    final (c, tx) = await ready();
    final done = c.keyDown('power');
    c.keyUp('power');
    await done;
    expect(tx.sent, hasLength(1));
    expect(decodeNecFrame(tx.sent.single.pattern), [0x40, 0xBF, 0x12, 0xED]);
    expect(c.sent.value, 1);
  });

  test('a held repeating key streams repeat codes until released', () async {
    final (c, tx) = await ready();
    final done = c.keyDown('vol_up', repeats: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    c.keyUp('vol_up');
    await done;
    expect(decodeNecFrame(tx.sent.first.pattern)[2], 0x1A);
    expect(tx.sent.length, greaterThanOrEqualTo(3));
    expect(tx.sent.skip(1).every(isNecRepeat), isTrue);
  });

  test('holding a non-repeating key still sends once', () async {
    final (c, tx) = await ready();
    final done = c.keyDown('netflix');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    c.keyUp('netflix');
    await done;
    expect(tx.sent, hasLength(1));
  });

  test('pressing another key stops the held one', () async {
    final (c, tx) = await ready();
    final held = c.keyDown('vol_up', repeats: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final tap = c.keyDown('mute');
    c.keyUp('mute');
    await Future.wait([held, tap]);
    expect(decodeNecFrame(tx.sent.last.pattern)[2], 0x10);
  });

  test('without an IR emitter nothing is sent and the user is told', () async {
    final (c, tx) = await ready(available: false);
    String? message;
    c.onProblem = (m) => message = m;
    await c.keyDown('power');
    expect(c.status.value, IrStatus.unavailable);
    expect(tx.sent, isEmpty);
    expect(message, noEmitterMessage);
  });

  test('a failed send is reported and stops repeating', () async {
    final (c, _) = await ready(fails: true);
    final messages = <String>[];
    c.onProblem = messages.add;
    await c.keyDown('vol_up', repeats: true);
    expect(messages, hasLength(1));
  });

  test('unknown keys are ignored', () async {
    final (c, tx) = await ready();
    await c.keyDown('no_such_key');
    expect(tx.sent, isEmpty);
  });
}
