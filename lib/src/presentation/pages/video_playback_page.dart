import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart' show XFile;

class SrtEntry {
  final Duration start;
  final Duration end;
  final String text;

  SrtEntry({required this.start, required this.end, required this.text});
}

/// Función para parsear el contenido de un archivo SRT en una lista de SrtEntry.
List<SrtEntry> parseSrt(String content) {
  final blocks = content.split(RegExp(r'\n\s*\n'));
  final entries = <SrtEntry>[];

  for (var block in blocks) {
    final lines = block.trim().split('\n');
    if (lines.length >= 3) {
      // La primera línea es el índice (se ignora)
      // La segunda línea es la línea de tiempo
      final timeLine = lines[1];
      final parts = timeLine.split(' --> ');
      if (parts.length != 2) continue;
      Duration parseTime(String s) {
        // Formato: 00:00:00,000
        final timeParts = s.split(RegExp(r'[:,]'));
        if (timeParts.length != 4) return Duration.zero;
        return Duration(
          hours: int.parse(timeParts[0]),
          minutes: int.parse(timeParts[1]),
          seconds: int.parse(timeParts[2]),
          milliseconds: int.parse(timeParts[3]),
        );
      }
      final start = parseTime(parts[0].trim());
      final end = parseTime(parts[1].trim());
      final text = lines.sublist(2).join('\n');
      entries.add(SrtEntry(start: start, end: end, text: text));
    }
  }
  return entries;
}

class VideoPlaybackPage extends StatefulWidget {
  final String videoPath;
  /// Opcional: si no se proporciona, se asume que el archivo SRT tiene el mismo nombre que el video
  final String? srtPath;

  const VideoPlaybackPage({Key? key, required this.videoPath, this.srtPath})
      : super(key: key);

  @override
  State<VideoPlaybackPage> createState() => _VideoPlaybackPageState();
}

class _VideoPlaybackPageState extends State<VideoPlaybackPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showSubtitles = false;
  List<SrtEntry> _subtitles = [];
  String _currentSubtitle = "";
  Timer? _subtitleTimer;
  late String effectiveSrtPath;

  @override
  void initState() {
    super.initState();
    // Si srtPath no se proporciona, se calcula a partir de videoPath
    effectiveSrtPath = widget.srtPath ??
        widget.videoPath.replaceAll(RegExp(r'\.mp4$', caseSensitive: false), '.srt');
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        // Si existe el archivo SRT, se carga
        if (File(effectiveSrtPath).existsSync()) {
          _loadSubtitles(effectiveSrtPath);
          _startSubtitleTimer();
        }
      });
  }

  Future<void> _loadSubtitles(String path) async {
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      _subtitles = parseSrt(content);
    }
  }

  void _startSubtitleTimer() {
    _subtitleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_controller.value.isInitialized && _showSubtitles) {
        final position = _controller.value.position;
        String subtitle = "";
        for (var entry in _subtitles) {
          if (position >= entry.start && position <= entry.end) {
            subtitle = entry.text;
            break;
          }
        }
        setState(() {
          _currentSubtitle = subtitle;
        });
      }
    });
  }

  @override
  void dispose() {
    _subtitleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleSubtitles() {
    setState(() {
      _showSubtitles = !_showSubtitles;
      if (!_showSubtitles) {
        _currentSubtitle = "";
      }
    });
  }

  void _shareVideo() {
    Share.shareXFiles([XFile(widget.videoPath)], text: 'Mira este video');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoPath.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareVideo,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
          ),
          if (_showSubtitles && _currentSubtitle.isNotEmpty)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: Colors.black54,
                child: Text(
                  _currentSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: _togglePlayPause,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: _shareVideo,
              child: const Icon(Icons.share),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: _toggleSubtitles,
              child: Icon(
                _showSubtitles ? Icons.subtitles_off : Icons.subtitles,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
