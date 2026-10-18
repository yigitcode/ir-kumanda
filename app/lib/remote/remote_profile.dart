import 'dart:convert';

import 'package:flutter/services.dart';

/// One physical remote: its protocol, address and the command of every key.
/// Loaded from `assets/remotes/*.json`.
class RemoteProfile {
  const RemoteProfile({
    required this.brand,
    required this.model,
    required this.address,
    required this.keys,
  });

  factory RemoteProfile.fromJson(Map<String, dynamic> json) {
    final protocol = json['protocol'];
    if (protocol != 'NEC') throw FormatException('Desteklenmeyen protokol: $protocol');
    final keys = (json['keys'] as Map<String, dynamic>).map((id, code) => MapEntry(id, _hex(code)));
    return RemoteProfile(
      brand: json['brand'] as String,
      model: json['model'] as String,
      address: _hex(json['address']),
      keys: Map.unmodifiable(keys),
    );
  }

  static Future<RemoteProfile> load(String asset) async =>
      RemoteProfile.fromJson(jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>);

  final String brand;
  final String model;
  final int address;
  final Map<String, int> keys;

  static int _hex(Object? value) {
    final text = (value as String).toLowerCase();
    return int.parse(text.startsWith('0x') ? text.substring(2) : text, radix: 16);
  }
}
