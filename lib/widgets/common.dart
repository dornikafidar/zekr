import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071F1A),
                AppColors.deepNight,
                Color(0xFF0A241C),
                Color(0xFF051410),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _GlowOrb(
            size: 280,
            color: AppColors.emerald.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -60,
          child: _GlowOrb(
            size: 220,
            color: AppColors.gold.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.35,
          left: MediaQuery.sizeOf(context).width * 0.55,
          child: _GlowOrb(
            size: 140,
            color: AppColors.softLeaf.withValues(alpha: 0.18),
          ),
        ),
        // Soft geometric pattern
        CustomPaint(
          painter: _PatternPainter(),
          child: const SizedBox.expand(),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mint.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
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
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, stroke: stroke),
        child: Center(child: child),
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
      ..color = AppColors.cardBorder.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

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
      stops: const [0.0, 0.55, 1.0],
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
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card.withValues(alpha: 0.85),
                AppColors.forest.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
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

/// Human-readable next unlock time, e.g. "morgen, 00:00".
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

TextStyle brandTitle({double size = 28}) => GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: AppColors.cream,
      letterSpacing: 1.2,
    );
