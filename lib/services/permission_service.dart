import 'package:permission_handler/permission_handler.dart';

/// Service for centralized permission management
class PermissionService {
  /// Check if microphone permission is granted
  static Future<bool> checkMicrophone() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  /// Returns true if permission is granted
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is permanently denied
  static Future<bool> isMicrophonePermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings (when permission is permanently denied)
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get detailed microphone permission status
  static Future<PermissionStatus> getMicrophoneStatus() async {
    return await Permission.microphone.status;
  }
}
