// lib/src/presentation/controllers/recording_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/models/geo_data_model.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/srt_generator.dart';

class RecordingController extends ChangeNotifier {
  final CameraService cameraService = CameraService();

  bool isRecording = false;
  String? currentVideoPath;

  // Para mostrar un icono con el último video grabado
  String? _lastVideoPath;
  String? get lastVideoPath => _lastVideoPath;

  // Lista de frames georreferenciados
  List<GeoData> _framesData = [];

  Timer? _timer;
  int frameCount = 0;
  int lastTimestampMs = 0;

  RecordingController();

  Future<void> startRecording() async {
    await cameraService.initCamera();

    currentVideoPath = await cameraService.startRecording();
    if (currentVideoPath == null) return;

    isRecording = true;
    notifyListeners();

    // 4 Hz => cada 250ms
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

    // Detenemos grabación
    await cameraService.stopRecording(currentVideoPath!);

    // Generamos el SRT
    await SrtGenerator.generateSrtFile(_framesData, videoFilePath: currentVideoPath!);

    // Guardamos la última ruta
    _lastVideoPath = currentVideoPath;

    // Limpiamos para la próxima
    _framesData.clear();
  }

  Future<void> _captureFrameData() async {
    frameCount++;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nowMs - lastTimestampMs;
    lastTimestampMs = nowMs;

    Position? pos = await LocationService.getCurrentPosition();

    // Yaw, Pitch, Roll simulados => 0.0
    final geo = GeoData(
      timestamp: DateTime.now(),
      latitude: pos?.latitude ?? 0.0,
      longitude: pos?.longitude ?? 0.0,
      relAltitude: pos?.altitude ?? 0.0,
      absAltitude: pos?.altitude ?? 0.0,
      yaw: 0.0,
      pitch: 0.0,
      roll: 0.0,
      frameCount: frameCount,
      diffTimeMs: diffMs,
    );

    _framesData.add(geo);
  }
}
