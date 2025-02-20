import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;

  // Valores de orientación (en radianes)
  double yaw = 0.0;
  double pitch = 0.0;
  double roll = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetSubscription;

  OrientationService() {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerEvent = event;
      _updateOrientation();
    });
    _magnetSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      _magnetometerEvent = event;
      _updateOrientation();
    });
  }

  void _updateOrientation() {
    if (_accelerometerEvent == null || _magnetometerEvent == null) return;

    // Normalizamos el vector de aceleración
    double ax = _accelerometerEvent!.x;
    double ay = _accelerometerEvent!.y;
    double az = _accelerometerEvent!.z;
    double normA = sqrt(ax * ax + ay * ay + az * az);
    if (normA == 0) return;
    ax /= normA;
    ay /= normA;
    az /= normA;

    // Normalizamos el vector del magnetómetro
    double mx = _magnetometerEvent!.x;
    double my = _magnetometerEvent!.y;
    double mz = _magnetometerEvent!.z;
    double normM = sqrt(mx * mx + my * my + mz * mz);
    if (normM == 0) return;
    mx /= normM;
    my /= normM;
    mz /= normM;

    // Calculamos el componente horizontal (H) de M respecto a la gravedad:
    // H = M - (A dot M) * A
    double dotAM = ax * mx + ay * my + az * mz;
    double hx = mx - dotAM * ax;
    double hy = my - dotAM * ay;
    double hz = mz - dotAM * az;
    double normH = sqrt(hx * hx + hy * hy + hz * hz);
    if (normH == 0) return;
    hx /= normH;
    hy /= normH;
    hz /= normH;

    // El azimuth (yaw) se calcula como el ángulo entre la proyección de H en el plano horizontal y el eje X:
    double azimuth = atan2(hy, hx);
    if (azimuth < 0) {
      azimuth += 2 * pi;
    }

    // Aproximamos pitch y roll usando los datos del acelerómetro
    double pitchCalc = asin(-ax);
    double rollCalc = atan2(ay, az);

    yaw = azimuth;
    pitch = pitchCalc;
    roll = rollCalc;
  }

  void dispose() {
    _accelSubscription?.cancel();
    _magnetSubscription?.cancel();
  }
}
