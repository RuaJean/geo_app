import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'video_playback_page.dart';
import '../widgets/srt_viewer_page.dart';
import 'gpx_viewer_page.dart';

extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class VideosListPage extends StatefulWidget {
  const VideosListPage({Key? key}) : super(key: key);

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
        .where((e) => e is Directory)
        .map((e) => e as Directory)
        .toList();

    return folders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Videos'),
      ),
      body: FutureBuilder<List<Directory>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final folders = snapshot.data ?? [];
          if (folders.isEmpty) {
            return const Center(child: Text('No hay videos guardados'));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final folderName = folder.path.split('/').last;
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folderName),
                subtitle: Text(folder.path),
                onTap: () => _showFolderOptions(folder),
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
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Opciones del Video',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Reproducir video'),
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
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Ver archivo SRT'),
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
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Ver archivo GPX'),
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
}
