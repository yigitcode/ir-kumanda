import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ir_kumanda/main.dart';
import 'package:ir_kumanda/remote/remote_controller.dart';
import 'package:ir_kumanda/ui/remote_key.dart';

import 'helpers.dart';

/// Logical phone sizes (dp) from small to large, plus a small tablet.
const _sizes = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(360, 780),
  Size(393, 851),
  Size(412, 915),
  Size(480, 1000),
  Size(800, 1280),
];

const _tabs = ['Kumanda', 'Rakamlar', 'Diğer'];

Finder _key(String id) => find.byWidgetPredicate((w) => w is RemoteKey && w.id == id);

Future<(RemoteController, FakeTransmitter)> _pumpApp(WidgetTester tester, Size size, {bool available = true}) async {
  tester.view.devicePixelRatio = 2.75;
  tester.view.physicalSize = size * 2.75;
  // Status bar and gesture-navigation bar.
  tester.view.padding = const FakeViewPadding(top: 24 * 2.75, bottom: 24 * 2.75);
  tester.view.viewPadding = const FakeViewPadding(top: 24 * 2.75, bottom: 24 * 2.75);
  addTearDown(tester.view.reset);

  final tx = FakeTransmitter(available: available);
  final controller = RemoteController(loadToshiba(), tx);
  await controller.init();
  await tester.pumpWidget(IrKumandaApp(controller: controller));
  await tester.pumpAndSettle();
  return (controller, tx);
}

void main() {
  for (final size in _sizes) {
    testWidgets('every tab lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _pumpApp(tester, size);
      for (final tab in _tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab tab');
      }
    });
  }

  testWidgets('every key on screen exists in the remote profile, with a 44 dp+ touch target', (tester) async {
    final (controller, _) = await _pumpApp(tester, const Size(320, 568));
    final keys = tester.widgetList<RemoteKey>(find.byType(RemoteKey, skipOffstage: false)).toList();
    expect(keys.length, greaterThan(40));
    for (final key in keys) {
      expect(controller.profile.keys, contains(key.id));
    }
    for (final element in find.byType(RemoteKey, skipOffstage: false).evaluate()) {
      final box = element.renderObject! as RenderBox;
      final id = (element.widget as RemoteKey).id;
      if (const {'red', 'green', 'yellow', 'blue'}.contains(id)) continue; // wide colour bars
      expect(box.size.shortestSide, greaterThanOrEqualTo(44), reason: id);
    }
  });

  testWidgets('pressing a key sends its code', (tester) async {
    final (_, tx) = await _pumpApp(tester, const Size(393, 851));
    await tester.tap(_key('youtube'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(decodeNecFrame(tx.sent.single.pattern), [0x40, 0xBF, 0xD2, 0x2D]);
  });

  testWidgets('phones without IR see an explanation', (tester) async {
    await _pumpApp(tester, const Size(360, 640), available: false);
    expect(find.text(noEmitterMessage), findsOneWidget);
    await tester.tap(_key('power'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(noEmitterMessage), findsNWidgets(2)); // banner + snack bar
  });
}
