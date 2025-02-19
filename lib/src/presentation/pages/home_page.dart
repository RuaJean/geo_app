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
    return ChangeNotifierProvider.value(
      value: _recordingController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Vista previa de la cámara (ocupando toda la pantalla)
              Consumer<RecordingController>(
                builder: (context, controller, child) {
                  return PreviewWidget(
                    controller: controller.cameraService.controller,
                  );
                },
              ),
              // Barra superior con contador y widget "HD - 30"
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Consumer<RecordingController>(
                        builder: (context, controller, _) {
                          return Text(
                            controller.elapsedTimeString,
                            style: TextStyle(
                              color: controller.isRecording ? Colors.red : Colors.white,
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
                      IconButton(
                        icon: const Icon(Icons.add_location, color: Colors.white),
                        onPressed: _recordingController.isRecording ? _onWaypointButtonPressed : null,
                      ),
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
