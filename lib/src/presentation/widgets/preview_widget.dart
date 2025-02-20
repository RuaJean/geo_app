import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PreviewWidget extends StatelessWidget {
  final CameraController? controller;

  const PreviewWidget({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: Text('Cámara no inicializada.', style: TextStyle(color: Colors.white)),
      );
    }
    // Rotamos la vista previa 90° para mostrarla en landscape
    return RotatedBox(
      quarterTurns: 1,
      child: CameraPreview(controller!),
    );
  }
}
