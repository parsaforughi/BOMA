import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/theme_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/otp/otp_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/purchase/purchase_screen.dart';
import 'screens/update/force_update_screen.dart';
import 'widgets/app_update_lifecycle_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AppUpdateLifecycleGuard(
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/force-update',
        builder: (context, state) {
          final args = state.extra as ForceUpdateRouteArgs?;
          if (args == null) {
            return const SplashScreen();
          }
          return ForceUpdateScreen(
            versionInfo: args.versionInfo,
            currentVersion: args.currentVersion,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/purchase',
        builder: (context, state) {
          final planId = state.extra as String? ?? '3month';
          return PurchaseScreen(planId: planId);
        },
      ),
    ],
  );
});

class BomaApp extends ConsumerWidget {
  const BomaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeState = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'BOMA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localeState.locale,
      supportedLocales: const [
        Locale('fa'),
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
