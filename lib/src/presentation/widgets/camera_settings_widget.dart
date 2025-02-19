import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/controllers/recording_controller.dart';
import 'dart:math';

class CameraSettingsWidget extends StatefulWidget {
  const CameraSettingsWidget({Key? key}) : super(key: key);

  @override
  State<CameraSettingsWidget> createState() => _CameraSettingsWidgetState();
}

class _CameraSettingsWidgetState extends State<CameraSettingsWidget> {
  bool _supports4K = false;

  @override
  void initState() {
    super.initState();
    _check4KSupport();
  }

  Future<void> _check4KSupport() async {
    final controller = Provider.of<RecordingController>(context, listen: false);
    final camera = controller.selectedCamera;
    if (camera == null) return;
    final supported = await controller.cameraService.getSupportedResolutions(camera);
    setState(() {
      _supports4K = supported.contains(ResolutionPreset.ultraHigh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RecordingController>(context);
    final is4K = (controller.selectedResolution == ResolutionPreset.ultraHigh);
    final is60 = (controller.selectedFrameRate == 60);
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPos = box.globalToLocal(details.globalPosition);
        final width = box.size.width;
        if (localPos.dx < width / 2) {
          // Toggle resolución
          if (is4K) {
            controller.selectedResolution = ResolutionPreset.high;
          } else {
            if (_supports4K) {
              controller.selectedResolution = ResolutionPreset.ultraHigh;
            }
          }
        } else {
          // Toggle FPS
          if (is60) {
            controller.selectedFrameRate = 30;
          } else {
            controller.selectedFrameRate = 60;
          }
        }
        setState(() {});
      },
      child: Text(
        "${is4K ? "4K" : "HD"} - ${is60 ? "60" : "30"}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
