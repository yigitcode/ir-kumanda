import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'remote_scope.dart';
import 'theme.dart';

enum KeyShape { circle, rounded, flat }

/// A pressable remote key. Sends on finger-down (no tap delay), stops on
/// finger-up; [repeats] keys keep sending while held.
class RemoteKey extends StatefulWidget {
  const RemoteKey({
    super.key,
    required this.id,
    required this.label,
    required this.child,
    this.width,
    this.height,
    this.shape = KeyShape.rounded,
    this.color = RemoteColors.key,
    this.repeats = false,
  });

  /// Key id in the remote profile, e.g. `vol_up`.
  final String id;

  /// Spoken by screen readers.
  final String label;
  final Widget child;
  final double? width;
  final double? height;
  final KeyShape shape;
  final Color color;
  final bool repeats;

  @override
  State<RemoteKey> createState() => _RemoteKeyState();
}

class _RemoteKeyState extends State<RemoteKey> {
  int? _pointer;

  bool get _pressed => _pointer != null;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    setState(() => _pointer = event.pointer);
    HapticFeedback.lightImpact();
    RemoteScope.read(context).keyDown(widget.id, repeats: widget.repeats);
  }

  void _up(PointerEvent event) {
    if (event.pointer != _pointer) return;
    setState(() => _pointer = null);
    RemoteScope.read(context).keyUp(widget.id);
  }

  void _semanticTap() {
    final controller = RemoteScope.read(context);
    controller.keyDown(widget.id);
    controller.keyUp(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.shape == KeyShape.flat;
    final base = widget.color;
    final face = _pressed ? Color.lerp(base, Colors.white, flat ? 0.10 : 0.14)! : base;
    final radius = widget.shape == KeyShape.circle ? null : BorderRadius.circular(18);

    final decoration = flat
        ? BoxDecoration(
            color: _pressed ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
            shape: BoxShape.circle,
          )
        : BoxDecoration(
            shape: widget.shape == KeyShape.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: radius,
            border: Border.all(color: RemoteColors.keyBorder),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(face, Colors.white, 0.06)!, face],
            ),
            boxShadow: _pressed
                ? const []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3))],
          );

    return Semantics(
      button: true,
      label: widget.label,
      onTap: _semanticTap,
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 70),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              decoration: decoration,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
