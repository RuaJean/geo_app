import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class PreviewWidget extends StatelessWidget {
  final CameraController? controller;

  const PreviewWidget({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: Text('Cámara no inicializada.'));
    }

    // Se utiliza el aspectRatio del controlador (ya ajustado internamente)
    final aspectRatio = controller!.value.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenRatio = constraints.maxWidth / constraints.maxHeight;
        double scale = aspectRatio / screenRatio;
        if (scale < 1) scale = 1 / scale;

        // Aplicamos una rotación fija de 180° para corregir la inversión
        return Transform.rotate(
          angle: pi,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: CameraPreview(controller!),
              ),
            ),
          ),
        );
      },
    );
  }
}
