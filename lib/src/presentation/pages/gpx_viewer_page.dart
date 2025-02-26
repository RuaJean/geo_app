import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart' show XFile;

class GPXViewerPage extends StatefulWidget {
  final String gpxPath;
  const GPXViewerPage({Key? key, required this.gpxPath}) : super(key: key);

  @override
  State<GPXViewerPage> createState() => _GPXViewerPageState();
}

class _GPXViewerPageState extends State<GPXViewerPage> {
  String? _content;

  @override
  void initState() {
    super.initState();
    _loadGpxContent();
  }

  Future<void> _loadGpxContent() async {
    try {
      final file = File(widget.gpxPath);
      final text = await file.readAsString();
      setState(() {
        _content = text;
      });
    } catch (e) {
      setState(() {
        _content = 'Error al leer el archivo GPX: $e';
      });
    }
  }

  void _shareGpx() {
    Share.shareXFiles([XFile(widget.gpxPath)], text: 'Compartir archivo GPX');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waypoints (GPX)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGpx,
          ),
        ],
      ),
      body: _content == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(_content!),
            ),
    );
  }
}
