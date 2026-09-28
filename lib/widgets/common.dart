import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A2A22),
                AppColors.deepNight,
                AppColors.abyss,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Warm gold wash from top
        Positioned(
          top: -size.height * 0.12,
          left: size.width * 0.15,
          right: size.width * 0.15,
          child: _GlowOrb(
            size: size.width * 0.9,
            color: AppColors.gold.withValues(alpha: 0.08),
            blur: 80,
          ),
        ),
        Positioned(
          top: -40,
          right: -50,
          child: _GlowOrb(
            size: 260,
            color: AppColors.emerald.withValues(alpha: 0.28),
            blur: 60,
          ),
        ),
        Positioned(
          bottom: -20,
          left: -70,
          child: _GlowOrb(
            size: 240,
            color: AppColors.softLeaf.withValues(alpha: 0.14),
            blur: 55,
          ),
        ),
        CustomPaint(
          painter: _LatticePainter(),
          child: const SizedBox.expand(),
        ),
        // Soft vignette
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [
                Colors.transparent,
                Color(0x66020403),
              ],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    this.blur = 50,
  });

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Soft islamic-inspired lattice of diamonds / octagon hints.
class _LatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mint.withValues(alpha: 0.035)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 56.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final cx = x + ((y ~/ step) % 2) * (step / 2);
        final path = Path()
          ..moveTo(cx, y - 10)
          ..lineTo(cx + 10, y)
          ..lineTo(cx, y + 10)
          ..lineTo(cx - 10, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 220,
    this.stroke = 10,
    this.glow = false,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final bool glow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.softLeaf.withValues(alpha: 0.12),
                    blurRadius: 48,
                  ),
                ],
              ),
            ),
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress, stroke: stroke),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    // Inner hairline
    final inner = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - stroke * 0.9, inner);

    if (progress <= 0) return;

    final sweep = (math.pi * 2) * progress.clamp(0.0, 1.0);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: const [
        AppColors.softLeaf,
        AppColors.mint,
        AppColors.gold,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final arc = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.stroke != stroke;
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.accent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardElevated.withValues(alpha: 0.92),
                AppColors.card.withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(
              color: accent
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : AppColors.cardBorder.withValues(alpha: 0.65),
              width: accent ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              if (accent)
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.mist,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.latin(
          fontSize: 11,
          weight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = AppColors.cream,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final btn = Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: filled
            ? AppColors.cardElevated.withValues(alpha: 0.85)
            : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

String formatCountdown(Duration d) {
  if (d.inDays >= 1) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    return '$days T. ${hours}h';
  }
  if (d.inHours >= 1) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    return '${hours}h ${mins}m';
  }
  final mins = d.inMinutes;
  final secs = d.inSeconds % 60;
  return '${mins}m ${secs}s';
}

String formatNextPeriodLabel(DateTime next) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final nextDay = DateTime(next.year, next.month, next.day);
  final time =
      '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';

  if (nextDay == today) return 'heute, $time';
  if (nextDay == today.add(const Duration(days: 1))) return 'morgen, $time';
  return '${next.day}.${next.month}., $time';
}

TextStyle brandTitle({double size = 28}) => AppTheme.latin(
      fontSize: size,
      weight: FontWeight.w700,
      color: AppColors.cream,
      letterSpacing: 0.8,
    );
