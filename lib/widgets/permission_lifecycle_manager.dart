import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/microphone_permission_service.dart';

/// Widget that handles app lifecycle events and manages permission cache
/// 
/// This widget ensures that when the app returns from the background,
/// we reset the permission cache so that permission status is re-checked
/// (in case user changed permissions in device settings)
class PermissionLifecycleManager extends StatefulWidget {
  final Widget child;

  const PermissionLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<PermissionLifecycleManager> createState() => _PermissionLifecycleManagerState();
}

class _PermissionLifecycleManagerState extends State<PermissionLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[PermissionLifecycleManager] Initialized and observing app lifecycle');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[PermissionLifecycleManager] Disposed and removed observer');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[PermissionLifecycleManager] App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      // App returned from background - reset permission cache
      // This ensures we re-check permissions (user may have changed them in settings)
      try {
        if (mounted) {
          final permissionService = MicrophonePermissionService();
          permissionService.resetCachedStatus();
          debugPrint('[PermissionLifecycleManager] Permission cache reset on app resume');
        }
      } catch (e) {
        debugPrint('[PermissionLifecycleManager] Error resetting permission cache: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
