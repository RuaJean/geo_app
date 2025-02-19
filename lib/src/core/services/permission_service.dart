import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static Future<bool> requestAllPermissions({bool usePreciseLocation = true}) async {
    List<Permission> permissionsToRequest = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    if (Platform.isAndroid) {
      if (usePreciseLocation) {
        permissionsToRequest.add(Permission.location);
      } else {
        permissionsToRequest.add(Permission.locationWhenInUse);
      }
      // Se solicita este permiso, pero su no otorgamiento no bloquea la inicialización.
      permissionsToRequest.add(Permission.manageExternalStorage);
    } else {
      permissionsToRequest.add(Permission.location);
    }

    final statuses = await permissionsToRequest.request();

    bool requiredGranted = statuses[Permission.camera]?.isGranted == true &&
        statuses[Permission.microphone]?.isGranted == true &&
        statuses[Permission.storage]?.isGranted == true &&
        ((Platform.isAndroid && usePreciseLocation)
            ? statuses[Permission.location]?.isGranted == true
            : (Platform.isAndroid
                ? statuses[Permission.locationWhenInUse]?.isGranted == true
                : true));

    if (Platform.isAndroid) {
      if (!(statuses[Permission.manageExternalStorage]?.isGranted ?? false)) {
        debugPrint("Warning: Permiso de Manage External Storage no otorgado, pero se continúa.");
      }
    }
    return requiredGranted;
  }
}
