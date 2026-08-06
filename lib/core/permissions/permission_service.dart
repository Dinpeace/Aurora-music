import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  /// Requests the permission needed to read music files.
  Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final Permission permission;

    // Android 13+ (API 33+) uses READ_MEDIA_AUDIO.
    // Older Android versions map to READ_EXTERNAL_STORAGE.
    permission = Permission.audio;

    if (await permission.isGranted) {
      return true;
    }

    final status = await permission.request();

    return status.isGranted;
  }

  /// Returns true if the permission has already been granted.
  Future<bool> hasAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    return Permission.audio.isGranted;
  }

  /// Opens the app settings if the user permanently denies permission.
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }
}