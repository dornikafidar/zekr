import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // No ImageFiltered blur — causes solid white rectangles on some Android GPUs.
    return ColoredBox(
      color: AppColors.deepNight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A2A22),
              AppColors.deepNight,
              AppColors.abyss,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
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
    final radius = BorderRadius.circular(22);
    return Material(
      color: AppColors.cardElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: accent
              ? AppColors.gold.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: accent ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.gold.withValues(alpha: 0.12),
        child: Padding(padding: padding, child: child),
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
    return '$days ر. ${hours}س';
  }
  if (d.inHours >= 1) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    return '${hours}س ${mins}د';
  }
  final mins = d.inMinutes;
  final secs = d.inSeconds % 60;
  return '${mins}د ${secs}ث';
}

String formatNextPeriodLabel(DateTime next) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final nextDay = DateTime(next.year, next.month, next.day);
  final time =
      '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';

  if (nextDay == today) return 'امروز، $time';
  if (nextDay == today.add(const Duration(days: 1))) return 'فردا، $time';
  return '${next.day}/${next.month}، $time';
}

TextStyle brandTitle({double size = 28}) => AppTheme.latin(
      fontSize: size,
      weight: FontWeight.w700,
      color: AppColors.cream,
      letterSpacing: 0.8,
    );
