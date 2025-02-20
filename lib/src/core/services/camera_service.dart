import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _cameraController;
  CameraDescription? _camera;
  ResolutionPreset _currentPreset = ResolutionPreset.medium; // Por defecto

  // Permite setear el ResolutionPreset (low, high, ultraHigh, etc.)
  void setResolutionPreset(ResolutionPreset preset) {
    _currentPreset = preset;
  }
 
  Future<void> initCamera() async {
    // Verificamos únicamente el permiso de cámara, ya que en startRecording se solicitaron todos los permisos.
    if (!await Permission.camera.isGranted) {
      PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception("Permiso de cámara no otorgado");
      }
    }
    
    final cameras = await availableCameras();
    // Seleccionamos la cámara trasera si existe
    _camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _camera!,
      _currentPreset,
      enableAudio: true,
    );

    await _cameraController?.initialize();
  }

  CameraController? get controller => _cameraController;

  Future<String?> startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    if (_cameraController!.value.isRecordingVideo) {
      return null; // Ya está grabando
    }

    final Directory? extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      return null;
    }

    final String parentDirPath = '${extDir.path}/GeoVideoRecorder';
    await Directory(parentDirPath).create(recursive: true);

    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
    final String videoFolderPath = '$parentDirPath/$formattedDate';
    await Directory(videoFolderPath).create(recursive: true);

    final String filePath = '$videoFolderPath/VID_$formattedDate.mp4';

    await _cameraController?.startVideoRecording();
    return filePath;
  }

  Future<void> stopRecording(String filePath) async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      XFile file = await _cameraController!.stopVideoRecording();
      await file.saveTo(filePath);
    }
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
  }
}
