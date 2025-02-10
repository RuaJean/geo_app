// lib/src/presentation/controllers/recording_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

// Ejemplo de tus clases importadas (ajusta las rutas según tu proyecto real)
import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/srt_generator.dart';
import '../../core/models/geo_data_model.dart';

class RecordingController extends ChangeNotifier {
  final CameraService cameraService = CameraService();

  bool isRecording = false;
  String? currentVideoPath;

  // Para mostrar un ícono del último video en la interfaz
  String? _lastVideoPath;
  String? get lastVideoPath => _lastVideoPath;

  // Frecuencia de captura
  Timer? _timer;
  int frameCount = 0;
  int lastTimestampMs = 0;

  // Lista de frames georreferenciados
  final List<GeoData> _framesData = [];

  // URL del PHP para subir el contenido del .srt
  static const String _uploadUrlText = 'http://18.227.72.168/upload_srt.php';

  // Inicia la grabación de video y la captura de datos
  Future<void> startRecording() async {
    await cameraService.initCamera();

    currentVideoPath = await cameraService.startRecording();
    if (currentVideoPath == null) return;

    isRecording = true;
    notifyListeners();

    // Capturamos datos 4 veces por segundo => 250ms
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

  // Detiene la grabación y genera+sube el archivo .srt
  Future<void> stopRecording() async {
    if (currentVideoPath == null) return;

    isRecording = false;
    notifyListeners();
    _timer?.cancel();

    // Detenemos la grabación de video
    await cameraService.stopRecording(currentVideoPath!);

    // Generamos el archivo .srt
    final srtPath = await SrtGenerator.generateSrtFile(
      _framesData,
      videoFilePath: currentVideoPath!,
    );

    // Subimos el contenido del .srt como texto
    final success = await uploadSrtAsText(srtPath);
    if (!success) {
      debugPrint('Error: no se pudo subir el archivo SRT como texto');
    }

    // Guardamos la última ruta de video
    _lastVideoPath = currentVideoPath;

    // Limpiamos la lista de frames
    _framesData.clear();
  }

  // Carga contenido del .srt y lo envía en un POST normal
  Future<bool> uploadSrtAsText(String srtPath) async {
    final file = File(srtPath);
    if (!file.existsSync()) {
      debugPrint('No existe el archivo SRT: $srtPath');
      return false;
    }

    try {
      // Leer contenido .srt
      final srtContent = await file.readAsString();

      // Hacemos un POST form-data (no multipart)
      final response = await http.post(
        Uri.parse(_uploadUrlText),
        body: {
          'srt_text': srtContent,
          'filename': p.basename(srtPath), // ejemplo: "VID_12345.srt"
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

  // Captura datos georreferenciados
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
      yaw: 0.0,
      pitch: 0.0,
      roll: 0.0,
      frameCount: frameCount,
      diffTimeMs: diffMs,
    );
    _framesData.add(geo);
  }
}
