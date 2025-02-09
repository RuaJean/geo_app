// lib/src/core/services/camera_service.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _cameraController;
  CameraDescription? _camera;

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    _camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _camera!,
      ResolutionPreset.medium,
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

    // Ruta base en almacenamiento externo
    final Directory? extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      return null;
    }

    final String parentDirPath = '${extDir.path}/GeoVideoRecorder';
    await Directory(parentDirPath).create(recursive: true);

    // Crea subcarpeta única para este video
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String videoFolderPath = '$parentDirPath/VID_$timestamp';
    await Directory(videoFolderPath).create(recursive: true);

    // Nombre del archivo .mp4
    final String filePath = '$videoFolderPath/VID_$timestamp.mp4';

    // Inicia la grabación (en un archivo temporal interno)
    await _cameraController?.startVideoRecording();

    // Retorna la ruta completa donde se guardará al detener
    return filePath;
  }

  Future<void> stopRecording(String filePath) async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      XFile file = await _cameraController!.stopVideoRecording();
      // Mover/Guardar el archivo temporal a 'filePath'
      await file.saveTo(filePath);
    }
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
  }
}
