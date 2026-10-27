import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/utils/geo_bearing.dart';

void main() {
  test('Berlin → Kaaba bearing is roughly southeast', () {
    final b = initialBearingDeg(
      fromLat: 52.52,
      fromLng: 13.405,
      toLat: 21.4225114,
      toLng: 39.8262060,
    );
    expect(b, greaterThan(130));
    expect(b, lessThan(160));
  });

  test('Tehran → Kaaba is ~ southwest-ish (known Qibla ~218°)', () {
    // Cross-check against common Qibla tables (~218° from Tehran).
    final b = initialBearingDeg(
      fromLat: 35.6892,
      fromLng: 51.3890,
      toLat: 21.4225114,
      toLng: 39.8262060,
    );
    expect(b, greaterThan(210));
    expect(b, lessThan(230));
  });

  test('needleRotationDeg wraps and zeros when aligned', () {
    expect(needleRotationDeg(90, 90), 0);
    expect(needleRotationDeg(10, 350), 20);
    expect(normalizeDeg(-90), 270);
  });

  test('trueHeading applies declination', () {
    final dec = magneticDeclinationDeg(35.6892, 51.3890);
    final trueH = trueHeadingDeg(
      magneticHeading: 100,
      lat: 35.6892,
      lng: 51.3890,
    );
    expect(trueH, closeTo(normalizeDeg(100 + dec), 0.01));
  });

  test('distance Tehran → Mashhad is hundreds of km', () {
    final d = distanceKm(
      fromLat: 35.6892,
      fromLng: 51.3890,
      toLat: 36.287778,
      toLng: 59.615556,
    );
    expect(d, greaterThan(700));
    expect(d, lessThan(900));
  });
}
