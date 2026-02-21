import 'package:flutter/material.dart';

import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/widgets/spline_background_stub.dart'
    if (dart.library.html) 'package:card_vault/core/widgets/spline_background_web.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: SplineBackground()),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background.withValues(alpha: 0.84),
                  const Color(0xFF020617).withValues(alpha: 0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    this.appBar,
    required this.body,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: GradientBackground(child: body),
    );
  }
}

