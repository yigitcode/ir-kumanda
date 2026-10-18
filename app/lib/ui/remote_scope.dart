import 'package:flutter/widgets.dart';

import '../remote/remote_controller.dart';

/// Makes the [RemoteController] reachable from every key widget.
class RemoteScope extends InheritedWidget {
  const RemoteScope({super.key, required this.controller, required super.child});

  final RemoteController controller;

  static RemoteController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemoteScope>()!.controller;

  /// For event handlers: looks the controller up without subscribing.
  static RemoteController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RemoteScope>()!.controller;

  @override
  bool updateShouldNotify(RemoteScope oldWidget) => controller != oldWidget.controller;
}
