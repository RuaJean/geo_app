import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _cameraController;
  CameraDescription? _camera;
  ResolutionPreset _currentPreset = ResolutionPreset.medium; // Por defecto

  // Permite setear el ResolutionPreset (low, high, ultraHigh, etc.)
  void setResolutionPreset(ResolutionPreset preset) {
    _currentPreset = preset;
  }
 
  Future<void> initCamera({CameraDescription? camera, ResolutionPreset? preset}) async {
    // Verificamos el permiso de cámara (suponiendo que otros permisos ya fueron solicitados).
    if (!await Permission.camera.isGranted) {
      PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception("Permiso de cámara no otorgado");
      }
    }

    final cameras = await availableCameras();
    _camera = camera ?? cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _currentPreset = preset ?? _currentPreset;

    _cameraController = CameraController(
      _camera!,
      _currentPreset,
      enableAudio: true,
    );

    // Inicializamos la cámara
    await _cameraController?.initialize();

    // IMPORTANTE: permitimos que la cámara rote automáticamente
    await _cameraController?.unlockCaptureOrientation();
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

  /// Retorna la lista de ResolutionPreset soportadas por la [camera].
  Future<List<ResolutionPreset>> getSupportedResolutions(CameraDescription camera) async {
    List<ResolutionPreset> availablePresets = [];
    List<ResolutionPreset> presets = [
      ResolutionPreset.ultraHigh,
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
      ResolutionPreset.medium,
      ResolutionPreset.low,
    ];

    for (var preset in presets) {
      try {
        CameraController tempController = CameraController(camera, preset, enableAudio: false);
        await tempController.initialize();
        availablePresets.add(preset);
        await tempController.dispose();
      } catch (_) {
        // Este preset no es soportado, se ignora.
      }
    }
    return availablePresets;
  }
}
