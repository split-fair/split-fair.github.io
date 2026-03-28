import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An animated judicial balance scale that tilts based on rent percentages.
///
/// [leftPercentage] and [rightPercentage] should be fractions that sum to ≤ 1.0.
/// Positive difference → left side heavier → scale tips left/down.
/// Uses an elastic spring curve so the scale overshoots and settles naturally.
class JudicialScaleWidget extends StatefulWidget {
  final double leftPercentage;
  final double rightPercentage;
  final String leftLabel;
  final String rightLabel;
  final double leftAmount;
  final double rightAmount;
  final Color leftColor;
  final Color rightColor;

  const JudicialScaleWidget({
    super.key,
    required this.leftPercentage,
    required this.rightPercentage,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftAmount,
    required this.rightAmount,
    this.leftColor = AppColors.primary,
    this.rightColor = AppColors.accent,
  });

  @override
  State<JudicialScaleWidget> createState() => _JudicialScaleWidgetState();
}

class _JudicialScaleWidgetState extends State<JudicialScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _tilt;

  /// Positive = left side heavier (tips left/down). Max ≈ ±32° at full imbalance.
  double get _targetTilt {
    final diff = widget.leftPercentage - widget.rightPercentage;
    return diff * (pi / 5.5);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _tilt = Tween<double>(begin: 0.0, end: _targetTilt).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    // Small delay so the rest of the screen paints before the scale animates
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(JudicialScaleWidget old) {
    super.didUpdateWidget(old);
    if (old.leftPercentage != widget.leftPercentage ||
        old.rightPercentage != widget.rightPercentage) {
      final current = _tilt.value;
      _tilt = Tween<double>(begin: current, end: _targetTilt).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 175,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _tilt,
            builder: (_, __) => CustomPaint(
              painter: _ScalePainter(
                tilt: _tilt.value,
                leftColor: widget.leftColor,
                rightColor: widget.rightColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── Labels ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.leftLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.leftColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${widget.leftAmount.toStringAsFixed(0)}/mo',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48), // visual gap over the pillar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.rightLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.rightColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${widget.rightAmount.toStringAsFixed(0)}/mo',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _ScalePainter extends CustomPainter {
  final double tilt;
  final Color leftColor;
  final Color rightColor;

  const _ScalePainter({
    required this.tilt,
    required this.leftColor,
    required this.rightColor,
  });

  static const _green = Color(0xFF00694C);
  static const _gold = Color(0xFF855400);
  static const _goldDark = Color(0xFFB87333);
  static const _chainGray = Color(0xFFBFC6CE);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final pivotY = size.height * 0.27;     // pivot fulcrum Y position
    final armLen = size.width * 0.37;      // half-beam length
    const chainLen = 54.0;                 // vertical chain length

    // ── Beam endpoints (rotated around pivot) ────────────────────────────
    // tilt > 0 → left side goes DOWN, right goes UP
    final leftEnd = Offset(
      cx - armLen * cos(tilt),
      pivotY + armLen * sin(tilt),
    );
    final rightEnd = Offset(
      cx + armLen * cos(tilt),
      pivotY - armLen * sin(tilt),
    );

    // ── Pan centres (chains hang straight down from beam tips) ───────────
    final leftPanC = Offset(leftEnd.dx, leftEnd.dy + chainLen);
    final rightPanC = Offset(rightEnd.dx, rightEnd.dy + chainLen);

    // ── Shared paints ────────────────────────────────────────────────────
    final greenStroke = Paint()
      ..color = _green
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final goldFill = Paint()
      ..color = _gold
      ..style = PaintingStyle.fill;

    final chainPaint = Paint()
      ..color = _chainGray
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    // ════════════════════════════════════════════════════════════════════
    // 1. BASE STAND
    // ════════════════════════════════════════════════════════════════════
    final baseY = size.height * 0.89;
    final baseBarY = baseY + 14.0;

    // Pillar shadow
    canvas.drawLine(
      Offset(cx + 1.5, pivotY + 8),
      Offset(cx + 1.5, baseY),
      Paint()
        ..color = Colors.black.withOpacity(0.07)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Pillar
    canvas.drawLine(
      Offset(cx, pivotY + 8),
      Offset(cx, baseY),
      greenStroke..strokeWidth = 4.5,
    );

    // Trapezoid foot
    final foot = Path()
      ..moveTo(cx - 5, baseY)
      ..lineTo(cx - 28, baseY + 14)
      ..lineTo(cx + 28, baseY + 14)
      ..lineTo(cx + 5, baseY)
      ..close();
    canvas.drawPath(foot, Paint()..color = _green);

    // Gold base bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 30, baseBarY, 60, 6),
        const Radius.circular(3),
      ),
      goldFill,
    );
    // Base bar rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 30, baseBarY, 60, 6),
        const Radius.circular(3),
      ),
      Paint()
        ..color = _goldDark.withOpacity(0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // ════════════════════════════════════════════════════════════════════
    // 2. TOP FINIAL
    // ════════════════════════════════════════════════════════════════════
    canvas.drawLine(
      Offset(cx, pivotY - 7),
      Offset(cx, pivotY - 24),
      Paint()
        ..color = _green
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    // Finial knob shadow
    canvas.drawCircle(Offset(cx + 1, pivotY - 26), 6.5, Paint()..color = Colors.black.withOpacity(0.08));
    // Finial knob
    canvas.drawCircle(Offset(cx, pivotY - 26), 7, goldFill);
    canvas.drawCircle(
      Offset(cx, pivotY - 26),
      7,
      Paint()
        ..color = _goldDark.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    // Shine dot
    canvas.drawCircle(Offset(cx - 2, pivotY - 28), 2, Paint()..color = Colors.white.withOpacity(0.7));

    // ════════════════════════════════════════════════════════════════════
    // 3. BEAM
    // ════════════════════════════════════════════════════════════════════
    // Beam shadow
    canvas.drawLine(
      Offset(leftEnd.dx + 1, leftEnd.dy + 2),
      Offset(rightEnd.dx + 1, rightEnd.dy + 2),
      Paint()
        ..color = Colors.black.withOpacity(0.07)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    // Beam
    canvas.drawLine(leftEnd, rightEnd, greenStroke..strokeWidth = 3.8);

    // Beam-end cap dots (gold)
    for (final pt in [leftEnd, rightEnd]) {
      canvas.drawCircle(pt, 4.5, goldFill);
      canvas.drawCircle(
        pt,
        4.5,
        Paint()
          ..color = _goldDark.withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // ════════════════════════════════════════════════════════════════════
    // 4. PIVOT HUB
    // ════════════════════════════════════════════════════════════════════
    // Outer ring shadow
    canvas.drawCircle(Offset(cx + 1, pivotY + 1), 11, Paint()..color = Colors.black.withOpacity(0.09));
    // Outer ring
    canvas.drawCircle(Offset(cx, pivotY), 11, goldFill);
    // Ring rim
    canvas.drawCircle(
      Offset(cx, pivotY),
      11,
      Paint()
        ..color = _goldDark.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    // Inner hub
    canvas.drawCircle(Offset(cx, pivotY), 5.5, Paint()..color = Colors.white.withOpacity(0.55));
    // Hub shine
    canvas.drawCircle(Offset(cx - 2.5, pivotY - 2.5), 2, Paint()..color = Colors.white.withOpacity(0.8));

    // ════════════════════════════════════════════════════════════════════
    // 5. CHAINS (3-segment dashed look)
    // ════════════════════════════════════════════════════════════════════
    _drawChain(canvas, leftEnd, leftPanC, chainPaint);
    _drawChain(canvas, rightEnd, rightPanC, chainPaint);

    // ════════════════════════════════════════════════════════════════════
    // 6. PANS
    // ════════════════════════════════════════════════════════════════════
    _drawPan(canvas, leftPanC, leftColor);
    _drawPan(canvas, rightPanC, rightColor);
  }

  /// Draws a chain as 3 evenly-spaced link dots + connecting lines.
  void _drawChain(Canvas canvas, Offset top, Offset bottom, Paint paint) {
    canvas.drawLine(top, bottom, paint);
    // Three small link ovals along the chain
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final mid = Offset.lerp(top, bottom, t)!;
      canvas.drawOval(
        Rect.fromCenter(center: mid, width: 5, height: 3),
        Paint()..color = _chainGray,
      );
    }
  }

  /// Draws a dish-shaped pan with fill, rim, and drop shadow.
  void _drawPan(Canvas canvas, Offset center, Color color) {
    const w = 50.0;
    const h = 11.0;

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 3.5), width: w + 8, height: h + 2),
      Paint()..color = Colors.black.withOpacity(0.07),
    );
    // Fill
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()..color = color.withOpacity(0.13),
    );
    // Rim
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
    // Inner highlight line
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, -1), width: w * 0.55, height: h * 0.35),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.tilt != tilt;
}
