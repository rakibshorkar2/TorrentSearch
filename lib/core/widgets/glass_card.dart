import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
    this.margin,
  });

  static const defaultPadding = EdgeInsets.all(TorrentFlowTheme.standardPadding);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final card = Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.glassDark : TorrentFlowTheme.glassLight,
        borderRadius: BorderRadius.circular(TorrentFlowTheme.cornerRadius),
        border: Border.all(
          color: isDark ? TorrentFlowTheme.glassBorderDark : TorrentFlowTheme.glassBorderLight,
          width: 0.5,
        ),
        boxShadow: TorrentFlowTheme.glassShadow(isDark),
      ),
      child: child,
    );

    if (onTap != null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.85,
        onPressed: onTap,
        child: card,
      );
    }
    return card;
  }
}

class GlassSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const GlassSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: TorrentFlowTheme.standardPadding,
        right: TorrentFlowTheme.standardPadding,
        top: TorrentFlowTheme.standardPadding,
        bottom: TorrentFlowTheme.tightPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.uppercaseFirst,
            style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TorrentFlowTheme.footnote.copyWith(
                color: TorrentFlowTheme.accent,
              ),
            ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String get uppercaseFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class HealthIndicator extends StatelessWidget {
  final int seeders;
  final int leechers;

  const HealthIndicator({
    super.key,
    required this.seeders,
    required this.leechers,
  });

  HealthLevel get _level {
    if (seeders <= 0) return HealthLevel.dead;
    final ratio = leechers > 0 ? seeders / leechers : seeders;
    if (ratio >= 5) return HealthLevel.excellent;
    if (ratio >= 2) return HealthLevel.good;
    if (ratio >= 1) return HealthLevel.ok;
    return HealthLevel.poor;
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (_level) {
      HealthLevel.excellent => TorrentFlowTheme.healthGreen,
      HealthLevel.good => TorrentFlowTheme.healthGreen,
      HealthLevel.ok => TorrentFlowTheme.healthYellow,
      HealthLevel.poor => TorrentFlowTheme.healthRed,
      HealthLevel.dead => TorrentFlowTheme.stopped,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

enum HealthLevel { excellent, good, ok, poor, dead }

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 36,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final ringColor = color ?? TorrentFlowTheme.accent;
    final bgColor = isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          ringColor: ringColor,
          bgColor: bgColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color ringColor;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final offset = strokeWidth / 2;
    final rect = Rect.fromLTWH(offset, offset, size.width - strokeWidth, size.height - strokeWidth);
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(rect.center, rect.width / 2, bgPaint);

    final fgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.ringColor != ringColor;
}
