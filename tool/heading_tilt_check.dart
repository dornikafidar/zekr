// Documents the Android getOrientation contract we rely on:
// azimuth from TYPE_ROTATION_VECTOR is tilt-compensated; near ±90° pitch
// it becomes unstable (gimbal lock with roll) — Flutter freezes then.
// Run: dart run --enable-asserts tool/heading_tilt_check.dart
void main() {
  const maxPitch = 55.0;
  assert(maxPitch > 0 && maxPitch < 90);
  // ignore: avoid_print
  print('compass uses SensorManager.getOrientation; freeze above $maxPitch° pitch');
}
