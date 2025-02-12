import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/recording_controller.dart';
import '../../presentation/widgets/preview_widget.dart';
import '../../presentation/widgets/record_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecordingController _recordingController;
  bool usePreciseLocation = true; // Valor por defecto

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
      await _recordingController.startRecording(usePreciseLocation: usePreciseLocation);
    } else {
      await _recordingController.stopRecording();
    }
    setState(() {});
  }

  Future<void> _onWaypointButtonPressed() async {
    // Almacena un waypoint en el momento actual
    await _recordingController.storeWaypoint();
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
        body: Column(
          children: [
            // Vista previa de la cámara
            Expanded(
              child: Consumer<RecordingController>(
                builder: (context, controller, child) {
                  return PreviewWidget(
                    controller: controller.cameraService.controller,
                  );
                },
              ),
            ),
            // Controles inferiores en un container
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón para almacenar waypoint (solo activo si se está grabando)
                  IconButton(
                    icon: const Icon(Icons.add_location, color: Colors.white),
                    onPressed: _recordingController.isRecording ? _onWaypointButtonPressed : null,
                  ),
                  // Switch para seleccionar precisión de ubicación
                  Row(
                    children: [
                      const Text('Preciso', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: usePreciseLocation,
                        onChanged: (value) {
                          setState(() {
                            usePreciseLocation = value;
                          });
                        },
                      ),
                    ],
                  ),
                  // Botón de grabación
                  RecordButton(
                    isRecording: _recordingController.isRecording,
                    onPressed: _onRecordButtonPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
