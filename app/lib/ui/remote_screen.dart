import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../remote/remote_controller.dart';
import 'pages.dart';
import 'remote_scope.dart';
import 'theme.dart';

const appVersion = '1.0.0'; // keep in step with pubspec.yaml

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    RemoteScope.of(context).onProblem = _showProblem;
  }

  void _showProblem(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final controller = RemoteScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: RemoteColors.surface,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _Header(controller: controller),
                  ValueListenableBuilder(
                    valueListenable: controller.status,
                    builder: (context, status, _) =>
                        status == IrStatus.unavailable ? const _NoEmitterBanner() : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: const [ControlPage(), NumbersPage(), MorePage()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.settings_remote_outlined),
              selectedIcon: Icon(Icons.settings_remote),
              label: 'Kumanda',
            ),
            NavigationDestination(icon: Icon(Icons.dialpad_rounded), label: 'Rakamlar'),
            NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'Diğer'),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final RemoteController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.brand,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RemoteColors.text)),
                Text('Kumanda ${profile.model}', style: const TextStyle(fontSize: 13, color: RemoteColors.muted)),
              ],
            ),
          ),
          _IrIndicator(sent: controller.sent),
          IconButton(
            tooltip: 'Hakkında',
            icon: const Icon(Icons.info_outline_rounded, color: RemoteColors.muted),
            onPressed: () => _showAbout(context, controller),
          ),
        ],
      ),
    );
  }
}

/// Small "IR" light that flashes whenever a signal goes out.
class _IrIndicator extends StatefulWidget {
  const _IrIndicator({required this.sent});

  final ValueNotifier<int> sent;

  @override
  State<_IrIndicator> createState() => _IrIndicatorState();
}

class _IrIndicatorState extends State<_IrIndicator> {
  bool _lit = false;
  Timer? _off;

  @override
  void initState() {
    super.initState();
    widget.sent.addListener(_flash);
  }

  @override
  void dispose() {
    widget.sent.removeListener(_flash);
    _off?.cancel();
    super.dispose();
  }

  void _flash() {
    setState(() => _lit = true);
    _off?.cancel();
    _off = Timer(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _lit = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lit ? RemoteColors.accent : RemoteColors.keyBorder,
              boxShadow: _lit ? [BoxShadow(color: RemoteColors.accent.withValues(alpha: 0.8), blurRadius: 8)] : const [],
            ),
          ),
          const SizedBox(width: 6),
          const Text('IR', style: TextStyle(fontSize: 11, letterSpacing: 1, color: RemoteColors.muted)),
        ],
      ),
    );
  }
}

class _NoEmitterBanner extends StatelessWidget {
  const _NoEmitterBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RemoteColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RemoteColors.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: RemoteColors.warning),
          SizedBox(width: 10),
          Expanded(child: Text(noEmitterMessage, style: TextStyle(fontSize: 13, color: RemoteColors.text))),
        ],
      ),
    );
  }
}

void _showAbout(BuildContext context, RemoteController controller) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: RemoteColors.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IR Kumanda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sürüm $appVersion · ${controller.profile.brand} ${controller.profile.model}',
                style: const TextStyle(color: RemoteColors.muted)),
            const SizedBox(height: 16),
            const Text(
              'Telefonun üst kenarındaki kızılötesi vericiyi televizyona doğrultun. '
              'Ses, kanal ve yön tuşlarını basılı tuttuğunuzda tuş art arda gönderilir.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => showLicensePage(context: context, applicationName: 'IR Kumanda', applicationVersion: appVersion),
              child: const Text('Açık kaynak lisansları'),
            ),
          ],
        ),
      ),
    ),
  );
}
