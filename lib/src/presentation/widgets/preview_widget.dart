import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PreviewWidget extends StatelessWidget {
  final CameraController? controller;

  const PreviewWidget({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32, 
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Iniciando cámara...',
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 16
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: AnimatedOpacity(
        opacity: controller!.value.isInitialized ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: AspectRatio(
          aspectRatio: 1 / controller!.value.aspectRatio,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }
}
