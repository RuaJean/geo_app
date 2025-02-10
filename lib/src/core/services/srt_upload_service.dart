import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class SrtUploadService {
  static const String _uploadUrl = 'http://18.227.72.168/upload_srt.php';

  /// Sube el archivo SRT [srtPath] al servidor.
  /// Retorna true si fue exitoso, false si falló.
  static Future<bool> uploadSrt(String srtPath) async {
    try {
      final file = File(srtPath);
      if (!file.existsSync()) {
        print('El archivo SRT no existe: $srtPath');
        return false;
      }

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..files.add(
          await http.MultipartFile.fromPath(
            'srt_file',
            file.path,
            filename: p.basename(srtPath), // nombre de archivo en el servidor
          ),
        );

      // Envía la petición
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('SRT subido correctamente: ${response.body}');
        return true;
      } else {
        print('Error al subir SRT, code: ${response.statusCode}, body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al subir SRT: $e');
      return false;
    }
  }
}
