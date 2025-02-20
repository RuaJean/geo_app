import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
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
  final OrientationService orientationService = OrientationService();

  CameraDescription? selectedCamera;
  ResolutionPreset selectedResolution = ResolutionPreset.medium;
  int selectedFrameRate = 30;

  bool isRecording = false;
  String? currentVideoPath;

  String? _lastVideoPath;
  String? get lastVideoPath => _lastVideoPath;

  DateTime? _recordingStartTime;
  Timer? _timer;
  int frameCount = 0;
  int lastTimestampMs = 0;
  final List<GeoData> _framesData = [];

  final List<Waypoint> _waypoints = [];
  int _waypointCount = 0;

  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;

  static const String _uploadUrlText = 'http://18.227.72.168/upload_srt.php';

  Future<void> startRecording({bool usePreciseLocation = true}) async {
    bool granted = await PermissionService.requestAllPermissions(usePreciseLocation: usePreciseLocation);
    if (!granted) {
      debugPrint('No se otorgaron los permisos necesarios.');
      return;
    }
    try {
      await cameraService.initCamera(
        camera: selectedCamera,
        preset: selectedResolution,
      );
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      return;
    }

    currentVideoPath = await cameraService.startRecording();
    if (currentVideoPath == null) return;

    _recordingStartTime = DateTime.now();

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(milliseconds: 250),
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
      notifyListeners(); // Para refrescar la UI (tiempo, etc.)
    });
  }

  Future<void> stopRecording() async {
    if (currentVideoPath == null) return;

    isRecording = false;
    notifyListeners();
    _timer?.cancel();
    _timer = null;

    await cameraService.stopRecording(currentVideoPath!);
    await _locationSubscription?.cancel();

    final srtPath = await SrtGenerator.generateSrtFile(
      _framesData,
      videoFilePath: currentVideoPath!,
    );

    final srtUploadSuccess = await uploadSrtAsText(srtPath);
    if (!srtUploadSuccess) {
      debugPrint('Error: no se pudo subir el archivo SRT como texto');
    }

    if (_waypoints.isNotEmpty) {
      final gpxPath = await GPXGenerator.generateGpxFile(_waypoints, videoFilePath: currentVideoPath!);
      debugPrint('GPX file generado: $gpxPath');
    }

    _lastVideoPath = currentVideoPath;
    _recordingStartTime = null;
    _framesData.clear();
    _waypoints.clear();
    _waypointCount = 0;
  }

  String get elapsedTimeString {
    if (!isRecording || _recordingStartTime == null) {
      return "00:00:00";
    }
    final diff = DateTime.now().difference(_recordingStartTime!);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
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

  Future<void> storeWaypoint({BuildContext? context}) async {
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

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waypoint creado exitosamente")),
      );
    }
  }

  Future<void> _captureFrameData() async {
    frameCount++;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastTimestampMs;
    lastTimestampMs = nowMs;

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
    _timer?.cancel();
    _locationSubscription?.cancel();
    orientationService.dispose();
    cameraService.dispose();
    super.dispose();
  }
}
