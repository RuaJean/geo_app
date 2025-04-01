import 'dart:io';
import '../models/geo_data_model.dart';

class SrtGenerator {
  static Future<String> generateSrtFile(List<GeoData> dataFrames, {required String videoFilePath}) async {
    String srtPath = videoFilePath.replaceAll('.mp4', '.srt');
    final buffer = StringBuffer();

    for (int i = 0; i < dataFrames.length; i++) {
      final geo = dataFrames[i];
      int index = i + 1;

      // Rango de tiempo para el fotograma
      final startMs = dataFrames.take(i).fold<int>(0, (acc, d) => acc + d.diffTimeMs);
      final endMs = startMs + geo.diffTimeMs;
      String startStr = _formatSrtTime(startMs);
      String endStr = _formatSrtTime(endMs);

      buffer.writeln('$index');
      buffer.writeln('$startStr --> $endStr');
      buffer.writeln(
        '<font size="28">FrameCnt: ${geo.frameCount}, DiffTime: ${geo.diffTimeMs}ms\n'
        '${geo.timestamp.toIso8601String().replaceAll("T", " ").substring(0, 23)}\n'
        '[iso: 100] [shutter: 1/3090.80] [fnum: 2.8] [ev: 0] [color_md: default] [ae_meter_md: 1] '
        '[focal_len: 24.00] [dzoom_ratio: 1.00], '
        '[latitude: ${geo.latitude}] [longitude: ${geo.longitude}] '
        '[rel_alt: ${geo.relAltitude} abs_alt: ${geo.absAltitude}] '
        '[yaw: ${geo.yaw} pitch: ${geo.pitch} roll: ${geo.roll}]'
        '</font>\n'
      );
    }

    final file = File(srtPath);
    await file.writeAsString(buffer.toString());
    return srtPath;
  }

  static String _formatSrtTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }
}
