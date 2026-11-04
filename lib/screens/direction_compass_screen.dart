import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../data/sacred_directions.dart';
import '../l10n/fa.dart';
import '../theme/app_theme.dart';
import '../utils/geo_bearing.dart';
import '../widgets/common.dart';

enum _LocIssue { none, serviceOff, denied, deniedForever, fail, compass }

/// GPS + magnetometer compass toward Kaaba / shrines.
class DirectionCompassScreen extends StatefulWidget {
  const DirectionCompassScreen({super.key});

  @override
  State<DirectionCompassScreen> createState() => _DirectionCompassScreenState();
}

class _DirectionCompassScreenState extends State<DirectionCompassScreen>
    with WidgetsBindingObserver {
  SacredTarget _target = kSacredTargets.first;
  Position? _pos;
  double? _heading; // true heading (°), declination-corrected, smoothed
  double? _declination;
  double? _compassAcc;
  bool _tiltedTooMuch = false;
  bool _aligned = false;
  static const _maxPitchDeg = 55.0;
  String? _error;
  _LocIssue _issue = _LocIssue.none;
  bool _loading = true;
  StreamSubscription? _compassSub;
  StreamSubscription<Position>? _posSub;

  static const _gpsSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 1,
  );
  static const _geomag = MethodChannel('zekr/geomag');
  static const _headingChannel = EventChannel('zekr/heading');
  static const _alignTolDeg = 3.0;

  /// Android reports magnetic north; iOS already reports true north.
  Future<void> _loadDeclination(Position p) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _declination = 0);
      return;
    }
    double? d;
    try {
      d = await _geomag.invokeMethod<double>('declination', {
        'lat': p.latitude,
        'lng': p.longitude,
        'alt': p.altitude,
      });
    } catch (_) {}
    d ??= magneticDeclinationDeg(p.latitude, p.longitude);
    if (mounted) setState(() => _declination = d);
  }

  /// iOS / devices without our native Android heading channel.
  void _listenPlugin() {
    _compassSub?.cancel();
    final events = FlutterCompass.events;
    if (events == null) {
      if (mounted) {
        setState(() {
          _issue = _LocIssue.compass;
          _error = Fa.compassUnavailable;
        });
      }
      return;
    }
    _compassSub =
        events.map((e) => (e.heading, e.accuracy, null)).listen(_onHeading);
  }

  void _listenAndroid() {
    _compassSub?.cancel();
    _compassSub = _headingChannel.receiveBroadcastStream().listen(
      (e) {
        final l = e as List;
        _onHeading((
          (l[0] as num).toDouble(),
          (l[1] as num?)?.toDouble(),
          l.length > 2 ? (l[2] as num?)?.toDouble() : null,
        ));
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _issue = _LocIssue.compass;
            _error = Fa.compassUnavailable;
          });
        }
      },
    );
  }

  void _onHeading((double?, double?, double?) e) {
    final (h, acc, pitch) = e;
    if (h == null || !mounted) return;
    final tooTilted = pitch != null && pitch.abs() > _maxPitchDeg;
    // Near vertical, Euler yaw locks with roll — freeze last good heading.
    if (tooTilted && _heading != null) {
      setState(() {
        _compassAcc = acc;
        _tiltedTooMuch = true;
      });
      return;
    }
    final raw = normalizeDeg(h + (_declination ?? 0));
    setState(() {
      _compassAcc = acc;
      _tiltedTooMuch = tooTilted;
      _heading = _heading == null
          ? raw
          : smoothHeadingDeg(_heading!, raw, alpha: 0.5);
    });
    final n = _needleNow();
    final aligned = n != null && math.min(n, 360 - n) <= _alignTolDeg;
    if (aligned && !_aligned) HapticFeedback.mediumImpact();
    _aligned = aligned;
  }

  double? _needleNow() {
    final p = _pos;
    final h = _heading;
    if (p == null || h == null) return null;
    return needleRotationDeg(
      initialBearingDeg(
        fromLat: p.latitude,
        fromLng: p.longitude,
        toLat: _target.lat,
        toLng: _target.lng,
      ),
      h,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Portrait-only: display-rotation remaps stay unambiguous while aiming.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSub?.cancel();
    _posSub?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_issue == _LocIssue.serviceOff ||
            _issue == _LocIssue.denied ||
            _issue == _LocIssue.deniedForever ||
            _pos == null)) {
      _start();
    }
  }

  Future<void> _openGpsSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppPermSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _issue = _LocIssue.none;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _loading = false;
          _issue = _LocIssue.serviceOff;
          _error = Fa.locationOff;
        });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _loading = false;
          _issue = _LocIssue.deniedForever;
          _error = Fa.locationDeniedForever;
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() {
          _loading = false;
          _issue = _LocIssue.denied;
          _error = Fa.locationDenied;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _gpsSettings,
      );
      await _loadDeclination(pos);
      if (!mounted) return;
      setState(() {
        _pos = pos;
        _loading = false;
        _issue = _LocIssue.none;
        _error = null;
      });

      await _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: _gpsSettings,
      ).listen((p) {
        if (!mounted) return;
        setState(() => _pos = p);
        _loadDeclination(p);
      });

      await _compassSub?.cancel();
      if (defaultTargetPlatform == TargetPlatform.android) {
        _listenAndroid();
      } else {
        _listenPlugin();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _issue = _LocIssue.fail;
          _error = Fa.locationFail;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = _pos;
    final heading = _heading;
    double? bearing;
    double? distKm;
    double? needle;
    if (pos != null) {
      bearing = initialBearingDeg(
        fromLat: pos.latitude,
        fromLng: pos.longitude,
        toLat: _target.lat,
        toLng: _target.lng,
      );
      distKm = distanceKm(
        fromLat: pos.latitude,
        fromLng: pos.longitude,
        toLat: _target.lat,
        toLng: _target.lng,
      );
      if (heading != null) {
        needle = needleRotationDeg(bearing, heading);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    BackCircleButton(onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(
                        Fa.directionCompass,
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 18,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconCircleButton(
                      icon: Icons.refresh_rounded,
                      onPressed: _start,
                    ),
                  ],
                ),
              ),
              if (MediaQuery.orientationOf(context) == Orientation.portrait)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Text(
                    Fa.directionHint,
                    textAlign: TextAlign.center,
                    style: AppTheme.latin(fontSize: 12, color: AppColors.mist),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kSacredTargets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = kSacredTargets[i];
                    final sel = t.id == _target.id;
                    return ChoiceChip(
                      label: Text(
                        t.nameFa,
                        style: AppTheme.latin(
                          fontSize: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                      selected: sel,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _target = t);
                      },
                      selectedColor: AppColors.gold.withValues(alpha: 0.28),
                      backgroundColor: AppColors.cardElevated,
                      side: BorderSide(
                        color: sel ? AppColors.gold : AppColors.cardBorder,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : _error != null && pos == null
                        ? _ErrorPane(
                            message: _error!,
                            onRetry: _start,
                            primaryLabel: switch (_issue) {
                              _LocIssue.serviceOff => Fa.enableLocation,
                              _LocIssue.deniedForever => Fa.openAppSettings,
                              _ => null,
                            },
                            onPrimary: switch (_issue) {
                              _LocIssue.serviceOff => _openGpsSettings,
                              _LocIssue.deniedForever => _openAppPermSettings,
                              _ => null,
                            },
                          )
                        : _CompassLayout(
                            top: [
                              const SizedBox(height: 12),
                              Text(
                                _target.nameFa,
                                style: AppTheme.latin(
                                  fontSize: 20,
                                  weight: FontWeight.w800,
                                  color: AppColors.gold,
                                ),
                              ),
                              Text(
                                _target.subtitleFa,
                                style: AppTheme.latin(
                                  fontSize: 13,
                                  color: AppColors.mist,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 4),
                                child: Text(
                                  Fa.compassLiveHint,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.latin(
                                    fontSize: 11,
                                    color: AppColors.mist,
                                  ),
                                ),
                              ),
                            ],
                            dial: _CompassDial(
                              headingDeg: heading,
                              qiblaBearingDeg: bearing,
                              needleDeg: needle,
                              aligned: _aligned,
                            ),
                            bottom: [
                              if (needle != null)
                                Text(
                                  _aligned
                                      ? Fa.facingTarget
                                      : needle <= 180
                                          ? Fa.turnRight(
                                              needle.toStringAsFixed(0))
                                          : Fa.turnLeft((360 - needle)
                                              .toStringAsFixed(0)),
                                  style: AppTheme.latin(
                                    fontSize: 16,
                                    weight: FontWeight.w800,
                                    color: _aligned
                                        ? Colors.lightGreenAccent
                                        : AppColors.cream,
                                  ),
                                ),
                              if (_tiltedTooMuch)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 6, 18, 0),
                                  child: Text(
                                    Fa.compassTiltWarn,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.latin(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              if (_compassAcc != null && _compassAcc! >= 45)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 6, 18, 0),
                                  child: Text(
                                    Fa.compassLowAccuracy,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.latin(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 20),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    children: [
                                      _MetaRow(
                                        label: Fa.bearing,
                                        value: bearing == null
                                            ? '—'
                                            : '${bearing.toStringAsFixed(2)}°',
                                      ),
                                      _MetaRow(
                                        label: Fa.distance,
                                        value: distKm == null
                                            ? '—'
                                            : distKm >= 1
                                                ? '${distKm.toStringAsFixed(2)} km'
                                                : '${(distKm * 1000).round()} m',
                                      ),
                                      _MetaRow(
                                        label: Fa.deviceHeading,
                                        value: heading == null
                                            ? '—'
                                            : '${heading.toStringAsFixed(1)}°',
                                      ),
                                      if (_declination != null &&
                                          _declination != 0)
                                        _MetaRow(
                                          label: Fa.declination,
                                          value:
                                              '${_declination!.toStringAsFixed(1)}°',
                                        ),
                                      if (pos != null)
                                        _MetaRow(
                                          label: Fa.gpsAccuracy,
                                          value: pos.accuracy.isFinite
                                              ? '±${pos.accuracy.round()} m'
                                              : '—',
                                        ),
                                      if (_error != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: AppTheme.latin(
                                              fontSize: 12,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Fa.compassCalibrateHint,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.latin(
                                          fontSize: 11,
                                          color: AppColors.mist,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Portrait: stacked with the dial filling the gap. Landscape: dial beside
/// a scrollable info column, so nothing overflows on short screens.
class _CompassLayout extends StatelessWidget {
  const _CompassLayout({
    required this.top,
    required this.dial,
    required this.bottom,
  });

  final List<Widget> top;
  final Widget dial;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    final dialBox = Center(child: dial);
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return Row(
        children: [
          Expanded(child: dialBox),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [...top, ...bottom]),
            ),
          ),
        ],
      );
    }
    return Column(children: [...top, Expanded(child: dialBox), ...bottom]);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.latin(fontSize: 13, color: AppColors.mist),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.latin(fontSize: 14, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({
    required this.message,
    required this.onRetry,
    this.primaryLabel,
    this.onPrimary,
  });

  final String message;
  final VoidCallback onRetry;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_rounded,
              size: 48, color: AppColors.mist),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.latin(fontSize: 15, color: AppColors.cream),
          ),
          const SizedBox(height: 18),
          if (primaryLabel != null && onPrimary != null) ...[
            FilledButton.icon(
              onPressed: onPrimary,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(primaryLabel!, style: AppTheme.latin()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.deepNight,
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(Fa.retryAudio, style: AppTheme.latin()),
          ),
        ],
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    this.headingDeg,
    this.qiblaBearingDeg,
    this.needleDeg,
    this.aligned = false,
  });

  final double? headingDeg;
  final double? qiblaBearingDeg;
  final double? needleDeg;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => _dial(
        math.max(
          120.0,
          math.min(math.min(c.maxWidth - 32, c.maxHeight - 16), 280.0),
        ),
      ),
    );
  }

  Widget _dial(double size) {
    final heading = headingDeg;
    final ready = heading != null && needleDeg != null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardElevated,
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          // Rose turns with the phone so N/O/S/W stay true-north in the world.
          if (heading != null)
            Transform.rotate(
              angle: -heading * math.pi / 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final label in [
                    (0.0, 'N'),
                    (90.0, 'O'),
                    (180.0, 'S'),
                    (270.0, 'W'),
                  ])
                    Transform.rotate(
                      angle: label.$1 * math.pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Transform.rotate(
                            angle: -label.$1 * math.pi / 180,
                            child: Text(
                              label.$2,
                              style: AppTheme.latin(
                                fontSize: 15,
                                weight: FontWeight.w800,
                                color: label.$2 == 'N'
                                    ? AppColors.gold
                                    : AppColors.mist,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (qiblaBearingDeg != null)
                    Transform.rotate(
                      angle: qiblaBearingDeg! * math.pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: size * 0.12),
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 22,
                            color: AppColors.gold.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Fixed phone-top needle → points where to face for Qibla.
          if (ready)
            Transform.rotate(
              angle: needleDeg! * math.pi / 180,
              child: Icon(
                Icons.navigation_rounded,
                size: size * 0.42,
                color: aligned ? Colors.lightGreenAccent : AppColors.gold,
              ),
            )
          else
            Text(
              heading == null ? '…' : Fa.compassWaiting,
              style: AppTheme.latin(color: AppColors.mist),
            ),
          // Facing marker (top of phone).
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.arrow_drop_down_rounded,
                size: 28,
                color: AppColors.cream.withValues(alpha: 0.9),
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
