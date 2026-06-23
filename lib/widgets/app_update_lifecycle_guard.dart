import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_version_info.dart';
import '../services/app_update_service.dart';

final appUpdateCheckProvider =
    FutureProvider<AppUpdateCheckResult>((ref) async {
  return AppUpdateService.checkForRequiredUpdate();
});

/// Re-checks for forced updates when the app returns to foreground.
class AppUpdateLifecycleGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AppUpdateLifecycleGuard({super.key, required this.child});

  @override
  ConsumerState<AppUpdateLifecycleGuard> createState() =>
      _AppUpdateLifecycleGuardState();
}

class _AppUpdateLifecycleGuardState extends ConsumerState<AppUpdateLifecycleGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckUpdate();
    }
  }

  Future<void> _recheckUpdate() async {
    final result = await AppUpdateService.checkForRequiredUpdate();
    if (!mounted || !result.updateRequired || result.versionInfo == null) {
      return;
    }
    context.go(
      '/force-update',
      extra: ForceUpdateRouteArgs(
        versionInfo: result.versionInfo!,
        currentVersion: result.currentVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ForceUpdateRouteArgs {
  final AppVersionInfo versionInfo;
  final String? currentVersion;

  const ForceUpdateRouteArgs({
    required this.versionInfo,
    this.currentVersion,
  });
}
