import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/orientation_service.dart';
import '../../core/utils/srt_generator.dart';
import '../../core/utils/gpx_generator.dart';
import '../../core/models/geo_data_model.dart';
import '../../core/models/waypoint.dart';
import '../../core/services/permission_service.dart';

class RecordingController extends ChangeNotifier {
  final CameraService cameraService = CameraService();
  // Servicio para obtener orientación real
  final OrientationService orientationService = OrientationService();

  bool isRecording = false;
  String? currentVideoPath;

  String? _lastVideoPath;
  String? get lastVideoPath => _lastVideoPath;

  Timer? _timer;
  int frameCount = 0;
  int lastTimestampMs = 0;
  final List<GeoData> _framesData = [];

  // Lista de waypoints y contador
  final List<Waypoint> _waypoints = [];
  int _waypointCount = 0;

  // Para obtener ubicaciones de forma continua
  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;

  // URL del PHP para subir el contenido del .srt (endpoint probado)
  static const String _uploadUrlText = 'http://18.227.72.168/upload_srt.php';

  Future<void> startRecording({bool usePreciseLocation = true}) async {
    bool granted = await PermissionService.requestAllPermissions(usePreciseLocation: usePreciseLocation);
    if (!granted) {
      debugPrint('No se otorgaron los permisos necesarios.');
      // return;
    }
    
    try {
      await cameraService.initCamera();
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      return;
    }

    currentVideoPath = await cameraService.startRecording();
    if (currentVideoPath == null) return;

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // o el valor que necesites
      intervalDuration: Duration(milliseconds: 250),
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
    });

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

    // Cancelar la suscripción a la ubicación
    await _locationSubscription?.cancel();

    // Generamos el archivo SRT (con yaw, pitch y roll reales)
    final srtPath = await SrtGenerator.generateSrtFile(
      _framesData,
      videoFilePath: currentVideoPath!,
    );

    final srtUploadSuccess = await uploadSrtAsText(srtPath);
    if (!srtUploadSuccess) {
      debugPrint('Error: no se pudo subir el archivo SRT como texto');
    }

    // Si hay waypoints, se genera el archivo GPX
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
    // Usa la última posición obtenida del stream
    if (_currentPosition == null) {
      debugPrint('No se pudo obtener la ubicación para el waypoint.');
      return;
    }
    _waypointCount++;
    final waypoint = Waypoint(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      altitude: _currentPosition!.altitude,
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

    // Usa la última posición obtenida del stream
    final pos = _currentPosition;
    final geo = GeoData(
      timestamp: DateTime.now(),
      latitude: pos?.latitude ?? 0.0,
      longitude: pos?.longitude ?? 0.0,
      relAltitude: pos?.altitude ?? 0.0,
      absAltitude: pos?.altitude ?? 0.0,
      yaw: orientationService.yaw,
      pitch: orientationService.pitch,
      roll: orientationService.roll,
      frameCount: frameCount,
      diffTimeMs: diffMs,
    );
    _framesData.add(geo);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    orientationService.dispose();
    cameraService.dispose();
    super.dispose();
  }
}
