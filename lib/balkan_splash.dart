import 'dart:async';

import 'package:flutter/material.dart';

class BalkanSplash extends StatefulWidget {
  final Widget child;

  const BalkanSplash({super.key, required this.child});

  @override
  State<BalkanSplash> createState() => _BalkanSplashState();
}

class _BalkanSplashState extends State<BalkanSplash> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return Scaffold(
      backgroundColor: Color(0xFF041226),
      body: MediaQuery.sizeOf(context).width >= 700
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 600,
                  ),
                  child: const Image(
                    image: AssetImage('assets/balkan_splash.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          : const SizedBox.expand(
              child: Image(
                image: AssetImage('assets/balkan_splash.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
    );
  }
}
