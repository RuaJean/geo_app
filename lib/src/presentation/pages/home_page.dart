import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/recording_controller.dart';
import '../../presentation/widgets/preview_widget.dart';
import '../../presentation/widgets/record_button.dart';
import '../../presentation/widgets/camera_settings_widget.dart';
import '../../config/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override 
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late RecordingController _recordingController;
  bool usePreciseLocation = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _recordingController = RecordingController();
    
    // Inicializa animación para waypoint
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _recordingController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    if (!_recordingController.isRecording) {
      await _recordingController.startRecording(usePreciseLocation: usePreciseLocation);
      // Mostrar un snackbar informativo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.videocam, color: Colors.white),
                SizedBox(width: 12),
                Text('Grabación iniciada'),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      await _recordingController.stopRecording();
      // Mostrar un snackbar informativo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Video guardado correctamente'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  Future<void> _onWaypointButtonPressed() async {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    await _recordingController.storeWaypoint(context: context);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 12),
              Text('Punto guardado correctamente'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos la orientación del dispositivo
    final orientation = MediaQuery.of(context).orientation;

    return ChangeNotifierProvider.value(
      value: _recordingController,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Consumer<RecordingController>(
                builder: (context, controller, _) {
                  return Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: controller.isRecording ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.elapsedTimeString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        body: Stack(
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
            
            // Panel de configuración
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 56, right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.overlay,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CameraSettingsWidget(),
                    ),
                  ),
                ),
              ),
            ),
            
            // Controles inferiores
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRect(
                child: BackdropFilter(
                  filter: const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.overlay,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Switch para seleccionar precisión de ubicación
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'GPS Preciso', 
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: usePreciseLocation,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    usePreciseLocation = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Row con los botones principales
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón waypoint (solo activo mientras se graba)
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _recordingController.isRecording
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add_location,
                                    color: _recordingController.isRecording
                                        ? Colors.orange[700]
                                        : Colors.white.withOpacity(0.5),
                                    size: 28,
                                  ),
                                  onPressed: _recordingController.isRecording 
                                      ? _onWaypointButtonPressed 
                                      : null,
                                ),
                              ),
                            ),
                            
                            // Botón de grabación (más grande)
                            RecordButton(
                              isRecording: _recordingController.isRecording,
                              onPressed: _onRecordButtonPressed,
                            ),
                            
                            // Placeholder para equilibrar el layout
                            const SizedBox(width: 56),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
