import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'video_player_page.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<File> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    // Obtenemos el directorio de almacenamiento externo (ajusta según plataforma)
    Directory? extDir = await getExternalStorageDirectory();
    if (extDir == null) return;
    String dirPath = '${extDir.path}/GeoVideoRecorder';
    Directory directory = Directory(dirPath);
    if (await directory.exists()) {
      List<FileSystemEntity> entities = directory.listSync(recursive: true);
      List<File> tempFiles = [];
      for (var entity in entities) {
        if (entity is File) {
          String ext = entity.path.split('.').last.toLowerCase();
          if (ext == 'mp4' || ext == 'gpx' || ext == 'srt') {
            tempFiles.add(entity);
          }
        }
      }
      setState(() {
        files = tempFiles;
      });
    }
  }

  Widget _buildFileTile(File file) {
    String fileName = file.path.split('/').last;
    String ext = fileName.split('.').last.toLowerCase();
    IconData icon;
    if (ext == 'mp4') {
      icon = Icons.videocam;
    } else if (ext == 'gpx') {
      icon = Icons.map;
    } else if (ext == 'srt') {
      icon = Icons.subtitles;
    } else {
      icon = Icons.insert_drive_file;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(fileName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para reproducir (solo para videos)
            if (ext == 'mp4')
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerPage(videoFile: file),
                    ),
                  );
                },
              ),
            // Botón para compartir
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.shareXFiles([XFile(file.path)], text: 'Compartir $fileName');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Videos y Archivos'),
      ),
      body: files.isEmpty
          ? const Center(child: Text('No se encontraron archivos.'))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                return _buildFileTile(files[index]);
              },
            ),
    );
  }
}
