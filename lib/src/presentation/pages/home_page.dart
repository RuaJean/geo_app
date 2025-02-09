// lib/src/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/recording_controller.dart';
import '../widgets/preview_widget.dart';
import '../widgets/record_button.dart';
import '../../core/services/permission_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecordingController _recordingController;

  @override
  void initState() {
    super.initState();
    _recordingController = RecordingController();
  }

  @override
  void dispose() {
    _recordingController.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    if (!_recordingController.isRecording) {
      bool granted = await PermissionService.requestAllPermissions();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se otorgaron todos los permisos necesarios.'),
        ));
        return;
      }
      await _recordingController.startRecording();
    } else {
      await _recordingController.stopRecording();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _recordingController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grabación de Video'),
        ),
        body: Consumer<RecordingController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // Vista previa de la cámara
                Positioned.fill(
                  child: PreviewWidget(
                    controller: controller.cameraService.controller,
                  ),
                ),
                // Controles inferiores (Row en la parte de abajo)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54, // semitransparente si gustas
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ícono en la esquina inferior izquierda
                        IconButton(
                          icon: const Icon(Icons.video_library, color: Colors.white),
                          onPressed: controller.lastVideoPath == null
                              ? null
                              : () {
                                  Navigator.pushNamed(context, '/videos');
                                },
                        ),
                        // Texto de estado en el centro
                        Text(
                          controller.isRecording ? 'Grabando...' : 'Detenido',
                          style: const TextStyle(color: Colors.white),
                        ),
                        // Botón de grabación en la derecha
                        RecordButton(
                          isRecording: controller.isRecording,
                          onPressed: _onRecordButtonPressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
