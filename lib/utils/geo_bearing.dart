import 'dart:math' as math;

/// WGS84 ellipsoid initial bearing (Vincenty), degrees clockwise from true north.
/// Falls back to spherical if the iteration does not converge (near-antipodal).
double initialBearingDeg({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  final vin = _vincentyForwardAzimuth(
    fromLat: fromLat,
    fromLng: fromLng,
    toLat: toLat,
    toLng: toLng,
  );
  if (vin != null) return vin;
  return _sphericalBearing(
    fromLat: fromLat,
    fromLng: fromLng,
    toLat: toLat,
    toLng: toLng,
  );
}

/// Haversine distance in kilometres (mean Earth radius).
double distanceKm({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const r = 6371.0088;
  final lat1 = _rad(fromLat);
  final lat2 = _rad(toLat);
  final dLat = _rad(toLat - fromLat);
  final dLng = _rad(toLng - fromLng);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Magnetic declination (°) east-positive via geomagnetic dipole (pole ~2025).
/// Converts true bearings ↔ magnetic compass headings (~1–2° typical mid-lat).
double magneticDeclinationDeg(double latDeg, double lngDeg) {
  // Geomagnetic north pole estimate ~2025.
  const poleLat = 86.50 * math.pi / 180;
  const poleLng = 164.04 * math.pi / 180;
  final lat = latDeg * math.pi / 180;
  final lng = lngDeg * math.pi / 180;
  final dLng = poleLng - lng;
  final y = math.sin(dLng);
  final x = math.cos(lat) * math.tan(poleLat) - math.sin(lat) * math.cos(dLng);
  return _deg(math.atan2(y, x));
}

/// Device magnetometer heading → true heading (0–360).
double trueHeadingDeg({
  required double magneticHeading,
  required double lat,
  required double lng,
}) =>
    normalizeDeg(magneticHeading + magneticDeclinationDeg(lat, lng));

/// Degrees to rotate a needle so it points to [trueBearing]
/// given device [trueHeading] (both 0–360, clockwise from true north).
double needleRotationDeg(double trueBearing, double trueHeading) =>
    normalizeDeg(trueBearing - trueHeading);

double normalizeDeg(double deg) {
  var d = deg % 360;
  if (d < 0) d += 360;
  return d;
}

/// Shortest-path exponential smooth toward [target] (keeps live compass stable).
double smoothHeadingDeg(double current, double target, {double alpha = 0.28}) {
  var d = target - current;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return normalizeDeg(current + d * alpha);
}

double _sphericalBearing({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  final lat1 = _rad(fromLat);
  final lat2 = _rad(toLat);
  final dLng = _rad(toLng - fromLng);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return normalizeDeg(_deg(math.atan2(y, x)));
}

/// Vincenty inverse → forward azimuth α1 on WGS84, or null if no converge.
double? _vincentyForwardAzimuth({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const f = 1 / 298.257223563;

  final phi1 = _rad(fromLat);
  final phi2 = _rad(toLat);
  final L = _rad(toLng - fromLng);
  if (L.abs() < 1e-15 && (phi1 - phi2).abs() < 1e-15) return 0;

  final u1 = math.atan((1 - f) * math.tan(phi1));
  final u2 = math.atan((1 - f) * math.tan(phi2));
  final sinU1 = math.sin(u1);
  final cosU1 = math.cos(u1);
  final sinU2 = math.sin(u2);
  final cosU2 = math.cos(u2);

  var lambda = L;
  double cosLambda = 0, sinLambda = 0, sinSigma = 0, cosSigma = 0, sigma = 0;
  double sinAlpha = 0, cosSqAlpha = 0, cos2SigmaM = 0;

  for (var i = 0; i < 100; i++) {
    sinLambda = math.sin(lambda);
    cosLambda = math.cos(lambda);
    final sinSqSigma = (cosU2 * sinLambda) * (cosU2 * sinLambda) +
        (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
            (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
    if (sinSqSigma.abs() < 1e-24) {
      // Coincident or antipodal edge — spherical is fine.
      return null;
    }
    sinSigma = math.sqrt(sinSqSigma);
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma = math.atan2(sinSigma, cosSigma);
    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha = 1 - sinAlpha * sinAlpha;
    cos2SigmaM =
        cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
    final C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
    final lambdaPrev = lambda;
    lambda = L +
        (1 - C) *
            f *
            sinAlpha *
            (sigma +
                C *
                    sinSigma *
                    (cos2SigmaM +
                        C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    if ((lambda - lambdaPrev).abs() < 1e-12) break;
    if (i == 99) return null;
  }

  final alpha1 = math.atan2(
    cosU2 * sinLambda,
    cosU1 * sinU2 - sinU1 * cosU2 * cosLambda,
  );
  return normalizeDeg(_deg(alpha1));
}

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;
