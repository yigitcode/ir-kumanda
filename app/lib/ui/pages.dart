import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controls.dart';
import 'remote_key.dart';
import 'theme.dart';

const _pagePadding = 16.0;

/// Everyday keys: power, apps, volume/channel, direction pad, navigation.
class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = uiScale(c, baseHeight: 470);
      final inner = c.maxWidth - 2 * _pagePadding;
      final round = 56 * s;
      final rockerWidth = 60 * s;
      final dpad = math.min(216 * s, inner - 2 * rockerWidth - 28 * s);
      final appGap = 10 * s;
      final appWidth = (inner - 2 * appGap) / 3;
      final appHeight = 58 * s;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LabeledKey(
                  id: 'power',
                  label: 'Güç',
                  icon: Icons.power_settings_new_rounded,
                  size: round,
                  iconColor: RemoteColors.power,
                ),
                LabeledKey(id: 'input', label: 'Kaynak', icon: Icons.input_rounded, size: round),
                LabeledKey(id: 'mute', label: 'Sessiz', icon: Icons.volume_off_rounded, size: round),
              ],
            ),
            Row(
              children: [
                AppKey(id: 'netflix', label: 'Netflix', width: appWidth, height: appHeight),
                SizedBox(width: appGap),
                AppKey(id: 'youtube', label: 'YouTube', width: appWidth, height: appHeight),
                SizedBox(width: appGap),
                AppKey(id: 'prime_video', label: 'Prime Video', width: appWidth, height: appHeight),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Rocker(
                  label: 'SES',
                  icon: Icons.volume_up_rounded,
                  upId: 'vol_up',
                  upLabel: 'Sesi aç',
                  upIcon: Icons.add_rounded,
                  downId: 'vol_down',
                  downLabel: 'Sesi kıs',
                  downIcon: Icons.remove_rounded,
                  width: rockerWidth,
                  height: dpad,
                ),
                DPad(size: dpad),
                Rocker(
                  label: 'KANAL',
                  icon: Icons.live_tv_rounded,
                  upId: 'ch_up',
                  upLabel: 'Sonraki kanal',
                  upIcon: Icons.keyboard_arrow_up_rounded,
                  downId: 'ch_down',
                  downLabel: 'Önceki kanal',
                  downIcon: Icons.keyboard_arrow_down_rounded,
                  width: rockerWidth,
                  height: dpad,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LabeledKey(id: 'back', label: 'Geri', icon: Icons.arrow_back_rounded, size: round),
                LabeledKey(id: 'home', label: 'Ana ekran', icon: Icons.home_rounded, size: round),
                LabeledKey(id: 'menu', label: 'Menü', icon: Icons.menu_rounded, size: round),
                LabeledKey(id: 'exit', label: 'Çıkış', icon: Icons.close_rounded, size: round),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Number pad for channel entry.
class NumbersPage extends StatelessWidget {
  const NumbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = uiScale(c, baseHeight: 480);
      final gap = 14 * s;
      final inner = c.maxWidth - 2 * _pagePadding;
      final width = (inner - 2 * gap) / 3;
      final height = math.min(width * 0.72, (c.maxHeight - 2 * _pagePadding - 3 * gap) / 4);

      Widget digit(int n) => RemoteKey(
            id: 'digit_$n',
            label: '$n',
            width: width,
            height: height,
            child: Text('$n', style: TextStyle(fontSize: height * 0.42, fontWeight: FontWeight.w500, color: RemoteColors.text)),
          );
      Widget row(List<Widget> keys) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: keys,
          );

      return Padding(
        padding: const EdgeInsets.all(_pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            row([digit(1), digit(2), digit(3)]),
            SizedBox(height: gap),
            row([digit(4), digit(5), digit(6)]),
            SizedBox(height: gap),
            row([digit(7), digit(8), digit(9)]),
            SizedBox(height: gap),
            row([
              IconKey(id: 'list', label: 'Kanal listesi', icon: Icons.format_list_bulleted_rounded, caption: 'Liste', width: width, height: height),
              digit(0),
              IconKey(id: 'guide', label: 'Program rehberi', icon: Icons.event_note_rounded, caption: 'Rehber', width: width, height: height),
            ]),
          ],
        ),
      );
    });
  }
}

/// Playback, colour keys and TV information keys.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = uiScale(c, baseHeight: 360);
      final gap = 12 * s;
      final inner = c.maxWidth - 2 * _pagePadding;
      final quarter = (inner - 3 * gap) / 4;
      final keyHeight = 56 * s;

      Widget row(List<Widget> keys) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: keys);
      Widget colour(String id, String label, Color color) => RemoteKey(
            id: id,
            label: label,
            width: quarter,
            height: 34 * s,
            color: color,
            child: const SizedBox.shrink(),
          );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const SectionTitle('OYNATMA'),
                SizedBox(height: gap),
                row([
                  IconKey(id: 'rewind', label: 'Geri sar', icon: Icons.fast_rewind_rounded, width: quarter, height: keyHeight, repeats: true),
                  IconKey(id: 'play', label: 'Oynat', icon: Icons.play_arrow_rounded, width: quarter, height: keyHeight),
                  IconKey(id: 'pause', label: 'Duraklat', icon: Icons.pause_rounded, width: quarter, height: keyHeight),
                  IconKey(id: 'fast_forward', label: 'İleri sar', icon: Icons.fast_forward_rounded, width: quarter, height: keyHeight, repeats: true),
                ]),
                SizedBox(height: gap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconKey(id: 'stop', label: 'Durdur', icon: Icons.stop_rounded, width: quarter, height: keyHeight),
                    SizedBox(width: gap),
                    IconKey(
                      id: 'record',
                      label: 'Kayıt',
                      icon: Icons.fiber_manual_record_rounded,
                      iconColor: RemoteColors.power,
                      width: quarter,
                      height: keyHeight,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                const SectionTitle('RENKLİ TUŞLAR'),
                SizedBox(height: gap),
                row([
                  colour('red', 'Kırmızı', RemoteColors.red),
                  colour('green', 'Yeşil', RemoteColors.green),
                  colour('yellow', 'Sarı', RemoteColors.yellow),
                  colour('blue', 'Mavi', RemoteColors.blue),
                ]),
              ],
            ),
            Column(
              children: [
                const SectionTitle('TELEVİZYON'),
                SizedBox(height: gap),
                row([
                  IconKey(id: 'guide', label: 'Program rehberi', icon: Icons.event_note_rounded, caption: 'Rehber', width: quarter, height: keyHeight * 1.15),
                  IconKey(id: 'text', label: 'Teletext', icon: Icons.subject_rounded, caption: 'Teletext', width: quarter, height: keyHeight * 1.15),
                  IconKey(id: 'info', label: 'Bilgi', icon: Icons.info_outline_rounded, caption: 'Bilgi', width: quarter, height: keyHeight * 1.15),
                  IconKey(id: 'list', label: 'Kanal listesi', icon: Icons.format_list_bulleted_rounded, caption: 'Liste', width: quarter, height: keyHeight * 1.15),
                ]),
              ],
            ),
          ],
        ),
      );
    });
  }
}
