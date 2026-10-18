import 'package:flutter/foundation.dart';

import '../ir/ir_signal.dart';
import '../ir/ir_transmitter.dart';
import '../ir/nec.dart';
import 'remote_profile.dart';

enum IrStatus { checking, ready, unavailable }

const noEmitterMessage = 'Bu telefonda kızılötesi (IR) verici yok. Uygulama yalnızca IR vericili telefonlarda çalışır.';

/// Turns key presses into IR bursts. A tap sends one frame; a held repeating
/// key keeps sending NEC repeat codes until it is released, like the original
/// remote, so the TV handles auto-repeat (volume ramps, list scrolling).
class RemoteController {
  RemoteController(this.profile, this._transmitter);

  final RemoteProfile profile;
  final IrTransmitter _transmitter;

  final ValueNotifier<IrStatus> status = ValueNotifier(IrStatus.checking);

  /// Increments after every burst; drives the on-screen IR indicator.
  final ValueNotifier<int> sent = ValueNotifier(0);

  /// Receives a user-facing message when a key cannot be sent.
  void Function(String message)? onProblem;

  String? _held;
  Future<void> _queue = Future.value();

  Future<void> init() async {
    status.value = await _transmitter.hasEmitter() ? IrStatus.ready : IrStatus.unavailable;
  }

  Future<void> keyDown(String key, {bool repeats = false}) async {
    final command = profile.keys[key];
    if (command == null) return;
    if (status.value == IrStatus.unavailable) {
      onProblem?.call(noEmitterMessage);
      return;
    }
    _held = key;
    await _send(Nec.frame(profile.address, command));
    // Two repeat codes per call keeps the stream gap-free while letting a
    // release stop it within ~0.2 s.
    while (repeats && _held == key) {
      await _send(Nec.repeat(2));
    }
  }

  void keyUp(String key) {
    if (_held == key) _held = null;
  }

  /// Bursts go out one after another; ConsumerIrManager is not re-entrant.
  Future<void> _send(IrSignal signal) {
    return _queue = _queue.then((_) async {
      try {
        await _transmitter.transmit(signal);
        sent.value++;
      } catch (_) {
        _held = null;
        onProblem?.call('Sinyal gönderilemedi. Tekrar deneyin.');
      }
    });
  }

  void dispose() {
    status.dispose();
    sent.dispose();
  }
}
