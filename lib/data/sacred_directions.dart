/// Sacred destinations for GPS + compass pointing.
class SacredTarget {
  const SacredTarget({
    required this.id,
    required this.nameFa,
    required this.subtitleFa,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String nameFa;
  final String subtitleFa;
  final double lat;
  final double lng;
}

/// Coordinates of shrines / Kaaba (WGS84).
const kSacredTargets = <SacredTarget>[
  // Kaaba geometric center (WGS84), high-precision reference used by Qibla apps.
  SacredTarget(
    id: 'kaaba',
    nameFa: 'قبله · کعبه',
    subtitleFa: 'مکه مکرمه',
    lat: 21.4225114,
    lng: 39.8262060,
  ),
  SacredTarget(
    id: 'karbala',
    nameFa: 'حرم امام حسین',
    subtitleFa: 'کربلا',
    lat: 32.616944,
    lng: 44.032778,
  ),
  SacredTarget(
    id: 'abbas',
    nameFa: 'حرم حضرت عباس',
    subtitleFa: 'کربلا',
    lat: 32.617222,
    lng: 44.035556,
  ),
  SacredTarget(
    id: 'najaf',
    nameFa: 'حرم امیرالمؤمنین',
    subtitleFa: 'نجف',
    lat: 31.995833,
    lng: 44.314444,
  ),
  SacredTarget(
    id: 'mashhad',
    nameFa: 'حرم امام رضا',
    subtitleFa: 'مشهد',
    lat: 36.287778,
    lng: 59.615556,
  ),
  SacredTarget(
    id: 'kazemayn',
    nameFa: 'حرم کاظمین',
    subtitleFa: 'بغداد',
    lat: 33.380278,
    lng: 44.338056,
  ),
  SacredTarget(
    id: 'qom',
    nameFa: 'حرم حضرت معصومه',
    subtitleFa: 'قم',
    lat: 34.641667,
    lng: 50.879167,
  ),
];
