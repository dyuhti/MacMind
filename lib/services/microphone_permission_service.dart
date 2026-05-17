import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission status wrapper for type-safe handling
enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  provisional,
}

/// Service to handle microphone permission requests and checks
class MicrophonePermissionService {
  static const String _debugTag = '[MicrophonePermissionService]';
  
  bool _permissionChecked = false;
  MicrophonePermissionStatus? _cachedStatus;

  /// Check if microphone permission is granted
  /// 
  /// Returns true only if permission is explicitly granted.
  /// Handles caching to avoid repeated permission prompts.
  Future<bool> isPermissionGranted() async {
    if (_permissionChecked && _cachedStatus == MicrophonePermissionStatus.granted) {
      return true;
    }

    final status = await _checkPermissionStatus();
    _permissionChecked = true;
    _cachedStatus = status;

    final isGranted = status == MicrophonePermissionStatus.granted;
    debugPrint('$_debugTag isPermissionGranted: $isGranted (status: $status)');
    return isGranted;
  }

  /// Reset cached permission status
  /// 
  /// Useful when the app returns to foreground after user changes settings
  void resetCachedStatus() {
    _permissionChecked = false;
    _cachedStatus = null;
    debugPrint('$_debugTag Cached permission status reset');
  }

  /// Request microphone permission from the user
  /// 
  /// Returns:
  /// - [MicrophonePermissionStatus.granted] if permission is granted
  /// - [MicrophonePermissionStatus.denied] if user denies the request
  /// - [MicrophonePermissionStatus.permanentlyDenied] if permission is blocked
  /// - [MicrophonePermissionStatus.restricted] on iOS when parental controls are enabled
  /// - [MicrophonePermissionStatus.provisional] on iOS 14+ (temporary permission)
  Future<MicrophonePermissionStatus> requestPermission() async {
    debugPrint('$_debugTag Requesting microphone permission...');

    final status = await Permission.microphone.request();

    final permissionStatus = _mapPermissionStatus(status);
    _permissionChecked = true;
    _cachedStatus = permissionStatus;

    debugPrint('$_debugTag Permission request result: $permissionStatus');

    // If permanently denied, automatically open app settings
    if (permissionStatus == MicrophonePermissionStatus.permanentlyDenied) {
      debugPrint('$_debugTag Permission permanently denied, opening app settings...');
      await _openAppSettings();
    }

    return permissionStatus;
  }

  /// Get the current permission status without requesting
  Future<MicrophonePermissionStatus> getCurrentStatus() async {
    final status = await _checkPermissionStatus();
    _cachedStatus = status;
    debugPrint('$_debugTag Current permission status: $status');
    return status;
  }

  /// Internal: Check the raw permission status
  Future<MicrophonePermissionStatus> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    return _mapPermissionStatus(status);
  }

  /// Map PermissionStatus to MicrophonePermissionStatus
  MicrophonePermissionStatus _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      return MicrophonePermissionStatus.granted;
    } else if (status.isDenied) {
      return MicrophonePermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return MicrophonePermissionStatus.permanentlyDenied;
    } else if (status.isRestricted) {
      return MicrophonePermissionStatus.restricted;
    } else if (status.isProvisional) {
      return MicrophonePermissionStatus.provisional;
    }
    return MicrophonePermissionStatus.denied;
  }

  /// Get user-friendly error message for a permission status
  String getErrorMessage(MicrophonePermissionStatus status) {
    switch (status) {
      case MicrophonePermissionStatus.granted:
        return 'Microphone permission granted';
      case MicrophonePermissionStatus.denied:
        return 'Microphone permission is required for voice input. Please grant permission to continue.';
      case MicrophonePermissionStatus.permanentlyDenied:
        return 'Microphone permission is permanently denied. Please enable it in app settings to use voice input.';
      case MicrophonePermissionStatus.restricted:
        return 'Microphone access is restricted on this device (parental controls may be active).';
      case MicrophonePermissionStatus.provisional:
        return 'Temporary microphone access granted. You may be prompted to provide full access.';
    }
  }

  /// Get detailed explanation for UI dialogs
  String getDetailedExplanation(MicrophonePermissionStatus status) {
    switch (status) {
      case MicrophonePermissionStatus.granted:
        return 'Microphone permission is enabled. You can now use voice input for medical calculations.';
      case MicrophonePermissionStatus.denied:
        return 'MacMind requires microphone access to enable voice-based medical input and calculations.';
      case MicrophonePermissionStatus.permanentlyDenied:
        return 'Microphone permission has been denied. To enable voice input, open app settings and grant microphone permission for MacMind.';
      case MicrophonePermissionStatus.restricted:
        return 'Microphone access is restricted on this device. Check device settings and parental controls.';
      case MicrophonePermissionStatus.provisional:
        return 'Temporary microphone access is active. Complete microphone access may be required for full functionality.';
    }
  }

  /// Get action button label for permission dialogs
  String getActionButtonLabel(MicrophonePermissionStatus status) {
    switch (status) {
      case MicrophonePermissionStatus.granted:
        return 'OK';
      case MicrophonePermissionStatus.denied:
        return 'Grant Permission';
      case MicrophonePermissionStatus.permanentlyDenied:
        return 'Open Settings';
      case MicrophonePermissionStatus.restricted:
        return 'OK';
      case MicrophonePermissionStatus.provisional:
        return 'Continue';
    }
  }

  /// Determine if user can be prompted for permission again
  bool canRequestPermission(MicrophonePermissionStatus status) {
    return status != MicrophonePermissionStatus.permanentlyDenied &&
        status != MicrophonePermissionStatus.restricted;
  }

  /// Open app settings for user to enable permission
  Future<void> _openAppSettings() async {
    debugPrint('$_debugTag Opening app settings...');
    try {
      final opened = await openAppSettings();
      if (!opened) {
        debugPrint('$_debugTag Failed to open app settings');
      } else {
        debugPrint('$_debugTag App settings opened successfully');
      }
    } catch (e) {
      debugPrint('$_debugTag Error opening app settings: $e');
    }
  }

  /// Get platform-specific permission name for debug info
  String getPlatformName() {
    if (Platform.isAndroid) {
      return 'Android (RECORD_AUDIO)';
    } else if (Platform.isIOS) {
      return 'iOS (NSMicrophoneUsageDescription)';
    }
    return 'Unknown Platform';
  }

  /// Get diagnostic information for debugging permission issues
  Future<Map<String, String>> getDiagnosticsInfo() async {
    final currentStatus = await getCurrentStatus();
    return <String, String>{
      'platform': getPlatformName(),
      'permission_status': currentStatus.toString(),
      'can_request': canRequestPermission(currentStatus).toString(),
      'platform_version': Platform.operatingSystemVersion,
    };
  }
}
