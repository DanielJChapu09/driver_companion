import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request all necessary XR permissions at once
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.storage,
      Permission.sensors,
      Permission.microphone,
      Permission.bluetooth,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Check if all XR-related permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    return (await Future.wait([
      Permission.camera.isGranted,
      Permission.locationWhenInUse.isGranted,
      Permission.locationAlways.isGranted,
      Permission.storage.isGranted,
      Permission.sensors.isGranted,
      Permission.microphone.isGranted,
      Permission.bluetooth.isGranted,
    ]))
        .every((granted) => granted);
  }

  /// Request a single permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Open app settings to manually enable permissions
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
