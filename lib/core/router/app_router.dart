import 'package:flutter/material.dart';

import 'package:card_vault/features/auth/login_page.dart';
import 'package:card_vault/features/auth/register_page.dart';
import 'package:card_vault/features/cards/add_card_page.dart';
import 'package:card_vault/features/cards/card_details_page.dart';
import 'package:card_vault/features/dashboard/dashboard_page.dart';
import 'package:card_vault/features/settings/settings_page.dart';
import 'package:card_vault/features/splash/splash_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String addCard = '/cards/add';
  static const String cardDetails = '/cards/details';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case AppRouter.splash:
        page = const SplashPage();
        break;
      case AppRouter.login:
        page = const LoginPage();
        break;
      case AppRouter.register:
        page = const RegisterPage();
        break;
      case AppRouter.dashboard:
        page = const DashboardPage();
        break;
      case AppRouter.addCard:
        page = const AddCardPage();
        break;
      case AppRouter.cardDetails:
        page = const CardDetailsPage();
        break;
      case AppRouter.settings:
        page = const SettingsPage();
        break;
      default:
        page = const SplashPage();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
