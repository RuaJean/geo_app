import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../pages/video_playback_page.dart';

import 'srt_viewer_page.dart';
import '../pages/gpx_viewer_page.dart';

extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class VideosListPage extends StatefulWidget {
  const VideosListPage({super.key});

  @override
  State<VideosListPage> createState() => _VideosListPageState();
}

class _VideosListPageState extends State<VideosListPage> {
  late Future<List<Directory>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _loadVideoFolders();
  }

  Future<List<Directory>> _loadVideoFolders() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) return [];

    final geoVideoDir = Directory('${dir.path}/GeoVideoRecorder');
    if (!geoVideoDir.existsSync()) {
      return [];
    }

    final entities = geoVideoDir.listSync();
    final List<Directory> folders = entities
        .whereType<Directory>()
        .map((e) => e as Directory)
        .toList();

    // Ordenar por fecha, más reciente primero
    folders.sort((a, b) {
      return b.path.compareTo(a.path);
    });

    return folders;
  }

  String _getFolderDateTime(String folderName) {
    try {
      // Asumiendo que el formato del nombre es yyyyMMdd_HHmmss
      final year = folderName.substring(0, 4);
      final month = folderName.substring(4, 6);
      final day = folderName.substring(6, 8);
      final hour = folderName.substring(9, 11);
      final minute = folderName.substring(11, 13);
      final second = folderName.substring(13, 15);
      
      final date = DateTime(
        int.parse(year),
        int.parse(month),
        int.parse(day),
        int.parse(hour),
        int.parse(minute),
        int.parse(second),
      );
      
      // Formato de fecha legible
      return DateFormat('dd/MM/yyyy - HH:mm').format(date);
    } catch (e) {
      return folderName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Videos'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Directory>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final folders = snapshot.data ?? [];
          
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay videos guardados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los videos que grabes aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final folderName = folder.path.split('/').last;
              final dateTime = _getFolderDateTime(folderName);
              
              // Buscar el archivo de video para obtener su miniatura
              final files = folder.listSync();
              final mp4File = files.firstWhereOrNull(
                (f) => f.path.toLowerCase().endsWith('.mp4'),
              ) as File?;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _showFolderOptions(folder),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Miniatura del video (simulada)
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: mp4File != null 
                            ? Image.asset(
                                'assets/video_placeholder.png', 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.video_file,
                                      size: 60,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.video_file,
                                  size: 60,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                      
                      // Información del video
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateTime,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Video con geolocalización',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.map_outlined,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GPS',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFolderOptions(Directory folder) {
    final files = folder.listSync();
    final mp4File = files.firstWhereOrNull(
      (f) => f.path.toLowerCase().endsWith('.mp4'),
    );
    final srtFile = files.firstWhereOrNull(
      (f) => f.path.toLowerCase().endsWith('.srt'),
    );
    final gpxFile = files.firstWhereOrNull(
      (f) => f.path.toLowerCase().endsWith('.gpx'),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Opciones del Video',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildOptionTile(
                icon: Icons.play_circle_filled,
                title: 'Reproducir video',
                subtitle: 'Ver el video grabado',
                isEnabled: mp4File != null,
                onTap: mp4File == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlaybackPage(videoPath: mp4File.path),
                          ),
                        );
                      },
              ),
              _buildOptionTile(
                icon: Icons.text_snippet_outlined,
                title: 'Ver archivo SRT',
                subtitle: 'Subtítulos con coordenadas GPS',
                isEnabled: srtFile != null,
                onTap: srtFile == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SrtViewerPage(srtPath: srtFile.path),
                          ),
                        );
                      },
              ),
              _buildOptionTile(
                icon: Icons.map_outlined,
                title: 'Ver archivo GPX',
                subtitle: 'Ruta GPS del recorrido',
                isEnabled: gpxFile != null,
                onTap: gpxFile == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GPXViewerPage(gpxPath: gpxFile.path),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return ListTile(
      enabled: isEnabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled 
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isEnabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isEnabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: isEnabled
          ? const Icon(Icons.chevron_right)
          : null,
      onTap: onTap,
    );
  }
}
