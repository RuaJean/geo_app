import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/recording_controller.dart';
import '../../presentation/widgets/preview_widget.dart';
import '../../presentation/widgets/record_button.dart';
import '../../presentation/widgets/camera_settings_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override 
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecordingController _recordingController;
  bool usePreciseLocation = true; 

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
    await _recordingController.storeWaypoint(context: context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos la orientación del dispositivo
    final orientation = MediaQuery.of(context).orientation;

    return ChangeNotifierProvider.value(
      value: _recordingController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Vista previa de la cámara ocupando toda la pantalla
              Positioned.fill(
                child: Consumer<RecordingController>(
                  builder: (context, controller, child) {
                    return PreviewWidget(
                      controller: controller.cameraService.controller,
                    );
                  },
                ),
              ),
              // Encabezado estilo iPhone
              Align(
                alignment: orientation == Orientation.portrait
                    ? Alignment.topCenter
                    : Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // En landscape: mostramos el tiempo y la configuración juntos
                      if (orientation == Orientation.landscape)
                        Consumer<RecordingController>(
                          builder: (context, controller, _) {
                            return Text(
                              controller.elapsedTimeString,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      if (orientation == Orientation.landscape)
                        const SizedBox(width: 12),
                      if (orientation == Orientation.landscape)
                        const CameraSettingsWidget(),
                      // En portrait: distribuimos el tiempo y la configuración en extremos
                      if (orientation == Orientation.portrait)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Consumer<RecordingController>(
                                builder: (context, controller, _) {
                                  return Text(
                                    controller.elapsedTimeString,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const CameraSettingsWidget(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Controles inferiores
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón waypoint (solo activo mientras se graba)
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
