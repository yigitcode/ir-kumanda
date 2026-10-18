import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ir/ir_transmitter.dart';
import 'remote/remote_controller.dart';
import 'remote/remote_profile.dart';
import 'ui/remote_scope.dart';
import 'ui/remote_screen.dart';
import 'ui/theme.dart';

const remoteAsset = 'assets/remotes/toshiba_ct-8543.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final profile = await RemoteProfile.load(remoteAsset);
  final controller = RemoteController(profile, PlatformIrTransmitter());
  runApp(IrKumandaApp(controller: controller));
  await controller.init();
}

class IrKumandaApp extends StatelessWidget {
  const IrKumandaApp({super.key, required this.controller});

  final RemoteController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IR Kumanda',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: RemoteScope(controller: controller, child: const RemoteScreen()),
    );
  }
}
