// Renders every tab at a few phone sizes to PNG files for visual review.
// Runs only when SCREENSHOT_DIR is set, e.g.
//   SCREENSHOT_DIR=build/screens FONT_DIR=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts flutter test test/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ir_kumanda/main.dart';
import 'package:ir_kumanda/remote/remote_controller.dart';

import 'helpers.dart';

final _outDir = Platform.environment['SCREENSHOT_DIR'];
final _fontDir = Platform.environment['FONT_DIR'];

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File('$_fontDir/$f').readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  const sizes = {'kucuk': Size(320, 600), 'orta': Size(360, 760), 'buyuk': Size(412, 915)};
  const tabs = ['Kumanda', 'Rakamlar', 'Diğer'];

  setUpAll(() async {
    if (_outDir == null) return;
    await _loadFont('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']);
    await _loadFont('MaterialIcons', ['materialicons-regular.otf']);
  });

  for (final entry in sizes.entries) {
    testWidgets('screenshots ${entry.key}', (tester) async {
      const dpr = 2.0;
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = entry.value * dpr;
      tester.view.padding = const FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
      tester.view.viewPadding = const FakeViewPadding(top: 24 * dpr, bottom: 24 * dpr);
      addTearDown(tester.view.reset);

      final controller = RemoteController(loadToshiba(), FakeTransmitter());
      await controller.init();
      const boundary = Key('shot');
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: IrKumandaApp(controller: controller)));
      await tester.pumpAndSettle();
      Directory(_outDir!).createSync(recursive: true);

      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
          final image = await render.toImage(pixelRatio: dpr);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_outDir/${entry.key}_${tabs.indexOf(tab)}.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }, skip: _outDir == null || _fontDir == null);
  }
}
