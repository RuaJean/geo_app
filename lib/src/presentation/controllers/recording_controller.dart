import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

// Importa tus clases según la estructura real del proyecto
import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/srt_generator.dart';
import '../../core/utils/gpx_generator.dart';
import '../../core/models/geo_data_model.dart';
import '../../core/models/waypoint.dart';
import '../../core/services/permission_service.dart';

class RecordingController extends ChangeNotifier {
  final CameraService cameraService = CameraService();

  bool isRecording = false;
  String? currentVideoPath;

  String? _lastVideoPath;
  String? get lastVideoPath => _lastVideoPath;

  Timer? _timer;
  int frameCount = 0;
  int lastTimestampMs = 0;
  final List<GeoData> _framesData = [];

  // Lista para almacenar waypoints y contador
  final List<Waypoint> _waypoints = [];
  int _waypointCount = 0;

  // URL del PHP para subir el contenido del .srt (se usa el endpoint probado)
  static const String _uploadUrlText = 'http://18.227.72.168/upload_srt.php';

  Future<void> startRecording({bool usePreciseLocation = true}) async {
    bool granted = await PermissionService.requestAllPermissions(usePreciseLocation: usePreciseLocation);
    if (!granted) {
      debugPrint('No se otorgaron los permisos necesarios.');
      return;
    }
    await cameraService.initCamera();

    currentVideoPath = await cameraService.startRecording();
    if (currentVideoPath == null) return;

    isRecording = true;
    notifyListeners();

    frameCount = 0;
    lastTimestampMs = DateTime.now().millisecondsSinceEpoch;

    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (!isRecording) {
        timer.cancel();
        return;
      }
      await _captureFrameData();
    });
  }

  Future<void> stopRecording() async {
    if (currentVideoPath == null) return;

    isRecording = false;
    notifyListeners();
    _timer?.cancel();

    await cameraService.stopRecording(currentVideoPath!);

    // Generamos el archivo SRT con los datos de georreferenciación (incluyendo yaw, pitch y roll)
    final srtPath = await SrtGenerator.generateSrtFile(
      _framesData,
      videoFilePath: currentVideoPath!,
    );

    // Subimos el contenido del SRT como texto
    final srtUploadSuccess = await uploadSrtAsText(srtPath);
    if (!srtUploadSuccess) {
      debugPrint('Error: no se pudo subir el archivo SRT como texto');
    }

    // Si se han almacenado waypoints, generamos el archivo GPX
    if (_waypoints.isNotEmpty) {
      final gpxPath = await GPXGenerator.generateGpxFile(_waypoints, videoFilePath: currentVideoPath!);
      debugPrint('GPX file generado: $gpxPath');
    }

    _lastVideoPath = currentVideoPath;
    _framesData.clear();
    _waypoints.clear();
    _waypointCount = 0;
  }

  Future<bool> uploadSrtAsText(String srtPath) async {
    final file = File(srtPath);
    if (!file.existsSync()) {
      debugPrint('No existe el archivo SRT: $srtPath');
      return false;
    }
    try {
      final srtContent = await file.readAsString();
      final response = await http.post(
        Uri.parse(_uploadUrlText),
        body: {
          'srt_text': srtContent,
          'filename': p.basename(srtPath),
        },
      );
      if (response.statusCode == 200) {
        debugPrint('Subida exitosa: ${response.body}');
        return true;
      } else {
        debugPrint(
          'Error al subir SRT (POST texto). Code: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Excepción al subir SRT como texto: $e');
      return false;
    }
  }

  Future<void> storeWaypoint() async {
    // Se obtiene la ubicación actual para el waypoint
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      debugPrint('No se pudo obtener la ubicación para el waypoint.');
      return;
    }
    _waypointCount++;
    final waypoint = Waypoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      timestamp: DateTime.now(),
      id: _waypointCount,
    );
    _waypoints.add(waypoint);
    debugPrint('Waypoint almacenado: id=${waypoint.id}, lat=${waypoint.latitude}, lon=${waypoint.longitude}');
  }

  Future<void> _captureFrameData() async {
    frameCount++;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastTimestampMs;
    lastTimestampMs = nowMs;

    final pos = await LocationService.getCurrentPosition();
    final geo = GeoData(
      timestamp: DateTime.now(),
      latitude: pos?.latitude ?? 0.0,
      longitude: pos?.longitude ?? 0.0,
      relAltitude: pos?.altitude ?? 0.0,
      absAltitude: pos?.altitude ?? 0.0,
      yaw: 0.0,   // Actualmente simulados; si tienes sensores, reemplaza estos valores
      pitch: 0.0,
      roll: 0.0,
      frameCount: frameCount,
      diffTimeMs: diffMs,
    );
    _framesData.add(geo);
  }
}
