import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/controllers/recording_controller.dart';
import '../../config/theme.dart';

class CameraSettingsWidget extends StatefulWidget {
  const CameraSettingsWidget({super.key});

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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Configuración de resolución
        _buildSettingItem(
          icon: Icons.hd,
          title: is4K ? "4K" : "HD",
          isActive: true,
          onTap: () {
            if (is4K) {
              controller.selectedResolution = ResolutionPreset.high;
            } else {
              if (_supports4K) {
                controller.selectedResolution = ResolutionPreset.ultraHigh;
              }
            }
            setState(() {});
          },
        ),
        
        const SizedBox(height: 12),
        
        // Configuración de FPS
        _buildSettingItem(
          icon: Icons.speed,
          title: "${is60 ? "60" : "30"} FPS",
          isActive: true,
          onTap: () {
            if (is60) {
              controller.selectedFrameRate = 30;
            } else {
              controller.selectedFrameRate = 60;
            }
            setState(() {});
          },
        ),
      ],
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
