import 'package:flutter/material.dart';

import 'package:card_vault/core/theme/app_theme.dart';
import 'package:card_vault/core/router/app_router.dart';

class CardVaultApp extends StatelessWidget {
  const CardVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
