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

    // Directorio base para la app
    final Directory? extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      return null;
    }

    final String parentDirPath = '${extDir.path}/GeoVideoRecorder';
    await Directory(parentDirPath).create(recursive: true);

    // Usamos fecha y hora formateadas para el nombre de la carpeta
    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}-'
        '${now.second.toString().padLeft(2, '0')}';
    final String videoFolderPath = '$parentDirPath/$formattedDate';
    await Directory(videoFolderPath).create(recursive: true);

    // Nombre del archivo de video
    final String filePath = '$videoFolderPath/VID_$formattedDate.mp4';

    // Inicia la grabación
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
