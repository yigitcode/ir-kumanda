import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'ir_signal.dart';

/// Where IR bursts go. The app uses [PlatformIrTransmitter]; tests use a fake.
abstract class IrTransmitter {
  Future<bool> hasEmitter();

  /// Completes once the whole burst has been sent.
  Future<void> transmit(IrSignal signal);
}

/// Sends through Android's ConsumerIrManager (see MainActivity.kt).
class PlatformIrTransmitter implements IrTransmitter {
  static const _channel = MethodChannel('ir_kumanda/ir');

  @override
  Future<bool> hasEmitter() async {
    try {
      return await _channel.invokeMethod<bool>('hasEmitter') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> transmit(IrSignal signal) => _channel.invokeMethod<void>('transmit', {
        'frequency': signal.frequency,
        'pattern': Int32List.fromList(signal.pattern),
      });
}
