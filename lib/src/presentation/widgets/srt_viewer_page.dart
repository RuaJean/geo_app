// lib/src/presentation/pages/srt_viewer_page.dart

import 'dart:io';
import 'package:flutter/material.dart';

class SrtViewerPage extends StatefulWidget {
  final String srtPath;

  const SrtViewerPage({Key? key, required this.srtPath}) : super(key: key);

  @override
  State<SrtViewerPage> createState() => _SrtViewerPageState();
}

class _SrtViewerPageState extends State<SrtViewerPage> {
  String? _content;

  @override
  void initState() {
    super.initState();
    _loadSrtContent();
  }

  Future<void> _loadSrtContent() async {
    try {
      final file = File(widget.srtPath);
      final text = await file.readAsString();
      setState(() {
        _content = text;
      });
    } catch (e) {
      setState(() {
        _content = 'Error al leer el archivo.\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivo SRT'),
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
