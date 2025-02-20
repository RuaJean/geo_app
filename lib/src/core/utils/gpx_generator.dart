import 'dart:io';
import '../models/waypoint.dart';

class GPXGenerator {
  static Future<String> generateGpxFile(List<Waypoint> waypoints, {required String videoFilePath}) async {
    // Se crea el archivo GPX en la misma carpeta del video, con el nombre waypoints.gpx
    final directory = File(videoFilePath).parent;
    final gpxPath = '${directory.path}/waypoints.gpx';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Geo Video Recorder">');

    for (final wp in waypoints) {
      final timeStr = wp.timestamp.toUtc().toIso8601String().split('.').first + 'Z';
      buffer.writeln('  <wpt lat="${wp.latitude}" lon="${wp.longitude}">');
      buffer.writeln('    <ele>${wp.altitude}</ele>');
      buffer.writeln('    <time>$timeStr</time>');
      buffer.writeln('    <name>${wp.id}</name>');
      buffer.writeln('  </wpt>');
    }
    buffer.writeln('</gpx>');

    final file = File(gpxPath);
    await file.writeAsString(buffer.toString());
    return gpxPath;
  }
}
