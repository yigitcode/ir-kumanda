import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand_marks.dart';
import 'remote_key.dart';
import 'theme.dart';

/// Size factor for a page: 1.0 on a 360 dp wide phone with [baseHeight] dp of
/// room (the page's natural height at 1.0), so the page always fits. Real
/// phones stay around 0.85–1.3; the 0.6 floor only matters on cramped screens.
double uiScale(BoxConstraints c, {required double baseHeight}) =>
    math.min(c.maxWidth / 360, c.maxHeight / baseHeight).clamp(0.6, 1.3).toDouble();

/// Round key with an icon and a caption underneath.
class LabeledKey extends StatelessWidget {
  const LabeledKey({
    super.key,
    required this.id,
    required this.label,
    required this.icon,
    required this.size,
    this.iconColor = RemoteColors.text,
  });

  final String id;
  final String label;
  final IconData icon;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RemoteKey(
          id: id,
          label: label,
          shape: KeyShape.circle,
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.42, color: iconColor),
        ),
        SizedBox(height: size * 0.12),
        ExcludeSemantics(
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(fontSize: (size * 0.22).clamp(11, 14).toDouble(), color: RemoteColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Circular direction pad with OK in the middle. Arrows repeat while held.
class DPad extends StatelessWidget {
  const DPad({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final zone = size * 0.32;
    Widget arrow(String id, String label, IconData icon, Alignment alignment) => Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.all(size * 0.02),
            child: RemoteKey(
              id: id,
              label: label,
              shape: KeyShape.flat,
              repeats: true,
              width: zone,
              height: zone,
              child: Icon(icon, size: size * 0.17, color: RemoteColors.text),
            ),
          ),
        );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: RemoteColors.keyBorder),
                gradient: const RadialGradient(colors: [Color(0xFF29303B), RemoteColors.key]),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))],
              ),
            ),
          ),
          arrow('up', 'Yukarı', Icons.keyboard_arrow_up_rounded, Alignment.topCenter),
          arrow('down', 'Aşağı', Icons.keyboard_arrow_down_rounded, Alignment.bottomCenter),
          arrow('left', 'Sol', Icons.keyboard_arrow_left_rounded, Alignment.centerLeft),
          arrow('right', 'Sağ', Icons.keyboard_arrow_right_rounded, Alignment.centerRight),
          Center(
            child: RemoteKey(
              id: 'ok',
              label: 'Tamam',
              shape: KeyShape.circle,
              width: size * 0.36,
              height: size * 0.36,
              color: const Color(0xFF2B3341),
              child: Text(
                'OK',
                style: TextStyle(fontSize: size * 0.085, fontWeight: FontWeight.w700, color: RemoteColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tall pill with an "up" key on top and a "down" key at the bottom
/// (volume, channel). Both repeat while held.
class Rocker extends StatelessWidget {
  const Rocker({
    super.key,
    required this.label,
    required this.icon,
    required this.upId,
    required this.upLabel,
    required this.upIcon,
    required this.downId,
    required this.downLabel,
    required this.downIcon,
    required this.width,
    required this.height,
  });

  final String label;
  final IconData icon;
  final String upId;
  final String upLabel;
  final IconData upIcon;
  final String downId;
  final String downLabel;
  final IconData downIcon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget key(String id, String keyLabel, IconData icon) => RemoteKey(
          id: id,
          label: keyLabel,
          shape: KeyShape.flat,
          repeats: true,
          width: width,
          height: width,
          child: Icon(icon, size: width * 0.42, color: RemoteColors.text),
        );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width / 2),
        border: Border.all(color: RemoteColors.keyBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF282F3A), RemoteColors.key],
        ),
      ),
      child: Column(
        children: [
          key(upId, upLabel, upIcon),
          Expanded(
            child: Center(
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: width * 0.34, color: RemoteColors.muted),
                      SizedBox(height: width * 0.04),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: width * 0.18,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: RemoteColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          key(downId, downLabel, downIcon),
        ],
      ),
    );
  }
}

/// Streaming-app shortcut: the app's mark above its name.
class AppKey extends StatelessWidget {
  const AppKey({super.key, required this.id, required this.label, required this.width, required this.height});

  final String id;
  final String label;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final markSize = height * 0.4;
    final Widget mark = switch (id) {
      'netflix' => NetflixMark(size: markSize),
      'youtube' => YouTubeMark(size: markSize),
      _ => PrimeVideoMark(size: markSize),
    };
    return RemoteKey(
      id: id,
      label: label,
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: height * 0.12, vertical: height * 0.1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(height: height * 0.08),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: height * 0.2, fontWeight: FontWeight.w600, color: RemoteColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded key with an icon (and optional caption inside).
class IconKey extends StatelessWidget {
  const IconKey({
    super.key,
    required this.id,
    required this.label,
    required this.icon,
    required this.width,
    required this.height,
    this.caption,
    this.iconColor = RemoteColors.text,
    this.repeats = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final double width;
  final double height;
  final String? caption;
  final Color iconColor;
  final bool repeats;

  @override
  Widget build(BuildContext context) {
    final iconSize = height * (caption == null ? 0.44 : 0.36);
    return RemoteKey(
      id: id,
      label: label,
      width: width,
      height: height,
      repeats: repeats,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            if (caption != null)
              Padding(
                padding: EdgeInsets.only(top: height * 0.04),
                child: Text(caption!, style: TextStyle(fontSize: height * 0.2, color: RemoteColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small heading above a group of keys. Pass the text already in capitals:
/// String.toUpperCase() is not Turkish-aware (i → I instead of İ).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: RemoteColors.muted),
      ),
    );
  }
}
