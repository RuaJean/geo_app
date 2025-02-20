class GeoData {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double relAltitude;
  final double absAltitude;
  final double yaw;
  final double pitch;
  final double roll;
  final int frameCount;
  final int diffTimeMs;

  GeoData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.relAltitude,
    required this.absAltitude,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.frameCount,
    required this.diffTimeMs,
  });
}