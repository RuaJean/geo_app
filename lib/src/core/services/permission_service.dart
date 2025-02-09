import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    // Solicita permisos de cámara, ubicación y almacenamiento.
    final statuses = await [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ].request();

    // Verifica si todos fueron concedidos
    return statuses.values.every((status) => status.isGranted);
  }
}
