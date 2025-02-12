import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions({bool usePreciseLocation = true}) async {
    List<Permission> permissionsToRequest = [
      Permission.camera,
      Permission.storage,
    ];

    if (Platform.isAndroid) {
      if (usePreciseLocation) {
        permissionsToRequest.add(Permission.location);
      } else {
        permissionsToRequest.add(Permission.locationWhenInUse);
      }
      // Opcional para Android 11+: permissionsToRequest.add(Permission.manageExternalStorage);
    } else {
      permissionsToRequest.add(Permission.location);
    }

    final statuses = await permissionsToRequest.request();
    return statuses.values.every((status) => status.isGranted);
  }
}
