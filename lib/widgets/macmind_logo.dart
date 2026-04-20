import 'package:flutter/material.dart';

/// Professional MacMind Logo Widget
/// Renders a scalable, high-quality medical/clinical logo
class MacMindLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const MacMindLogo({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF4A90E2);
    final accent = accentColor ?? Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          primaryColor: primary,
          accentColor: accent,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _LogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw gradient circle background
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.95),
          primaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, gradientPaint);

    // Draw subtle outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accentColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.02,
    );

    // Settings for element painting
    final fillPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final scale = size.width;
    final baseX = center.dx;
    final baseY = center.dy;

    // === IV Stand / Anesthetic Equipment (Upper Left) ===
    final standX = baseX - scale * 0.15;
    final standY = baseY - scale * 0.15;

    // Stand base
    canvas.drawRect(
      Rect.fromLTWH(
        standX - scale * 0.03,
        standY + scale * 0.2,
        scale * 0.06,
        scale * 0.15,
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Horizontal foot
    canvas.drawRect(
      Rect.fromLTWH(
        standX - scale * 0.06,
        standY + scale * 0.33,
        scale * 0.12,
        scale * 0.03,
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Main vertical pole
    canvas.drawLine(
      Offset(standX, standY + scale * 0.2),
      Offset(standX, standY - scale * 0.08),
      Paint()
        ..color = accentColor
        ..strokeWidth = scale * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // IV bag top bracket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          standX - scale * 0.04,
          standY - scale * 0.15,
          scale * 0.08,
          scale * 0.06,
        ),
        Radius.circular(scale * 0.01),
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.025,
    );

    // Drip chamber indicator
    canvas.drawLine(
      Offset(standX, standY - scale * 0.09),
      Offset(standX, standY + scale * 0.02),
      Paint()
        ..color = accentColor
        ..strokeWidth = scale * 0.025
        ..strokeCap = StrokeCap.round,
    );

    // === Monitor / Display (Right Side) ===
    final monitorX = baseX + scale * 0.08;
    final monitorY = baseY - scale * 0.12;

    // Monitor bezel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          monitorX - scale * 0.12,
          monitorY,
          scale * 0.24,
          scale * 0.18,
        ),
        Radius.circular(scale * 0.02),
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // Monitor screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          monitorX - scale * 0.1,
          monitorY + scale * 0.015,
          scale * 0.2,
          scale * 0.15,
        ),
        Radius.circular(scale * 0.01),
      ),
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

    // Monitor stand/base
    canvas.drawRect(
      Rect.fromLTWH(
        monitorX - scale * 0.04,
        monitorY + scale * 0.18,
        scale * 0.08,
        scale * 0.035,
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    // EKG/Pulse waveform line
    _drawWaveform(
      canvas,
      Offset(monitorX - scale * 0.08, monitorY + scale * 0.1),
      scale * 0.16,
      scale * 0.04,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.6)
        ..strokeWidth = scale * 0.018
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Status indicator dots
    final dotRadius = scale * 0.015;
    canvas.drawCircle(Offset(monitorX - scale * 0.07, monitorY + scale * 0.035), dotRadius, fillPaint);
    canvas.drawCircle(Offset(monitorX - scale * 0.01, monitorY + scale * 0.035), dotRadius, fillPaint);
    canvas.drawCircle(Offset(monitorX + scale * 0.05, monitorY + scale * 0.035), dotRadius, fillPaint);

    // === Pulse/Clinical Check (Lower Right) ===
    final pulseX = baseX + scale * 0.12;
    final pulseY = baseY + scale * 0.08;

    // Finger contact area (ellipse)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pulseX, pulseY),
        width: scale * 0.12,
        height: scale * 0.16,
      ),
      Paint()
        ..color = accentColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );

    // Pulse indicators
    canvas.drawCircle(Offset(pulseX - scale * 0.04, pulseY - scale * 0.02), scale * 0.018, fillPaint);
    canvas.drawCircle(Offset(pulseX + scale * 0.04, pulseY - scale * 0.02), scale * 0.018, fillPaint);

    // === Security/Protection Shield (Lower Left) ===
    final shieldX = baseX - scale * 0.12;
    final shieldY = baseY + scale * 0.08;

    // Shield outline
    final shieldPath = Path()
      ..moveTo(shieldX, shieldY - scale * 0.08)
      ..lineTo(shieldX, shieldY + scale * 0.04)
      ..cubicTo(
        shieldX,
        shieldY + scale * 0.12,
        shieldX + scale * 0.08,
        shieldY + scale * 0.16,
        shieldX + scale * 0.08,
        shieldY + scale * 0.16,
      )
      ..cubicTo(
        shieldX + scale * 0.08,
        shieldY + scale * 0.16,
        shieldX + scale * 0.16,
        shieldY + scale * 0.12,
        shieldX + scale * 0.16,
        shieldY + scale * 0.04,
      )
      ..lineTo(shieldX + scale * 0.16, shieldY - scale * 0.08)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.03
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Checkmark inside shield (security)
    canvas.drawPath(
      _createCheckmarkPath(
        Offset(shieldX + scale * 0.04, shieldY + scale * 0.06),
        scale * 0.06,
      ),
      Paint()
        ..color = accentColor
        ..strokeWidth = scale * 0.03
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Center accent circle (subtle quality indicator)
    canvas.drawCircle(
      center,
      radius * 0.58,
      Paint()
        ..color = accentColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.01,
    );
  }

  void _drawWaveform(
    Canvas canvas,
    Offset startPos,
    double width,
    double height,
    Paint paint,
  ) {
    final path = Path()..moveTo(startPos.dx, startPos.dy);

    // Create a smooth ECG-like waveform
    const points = 5;
    final spacing = width / points;

    for (int i = 0; i <= points; i++) {
      final x = startPos.dx + (i * spacing);
      final y = i % 2 == 0 ? startPos.dy : startPos.dy - height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.quadraticBezierTo(
          x - spacing / 2,
          (startPos.dy + y) / 2,
          x,
          y,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  Path _createCheckmarkPath(Offset start, double size) {
    final path = Path();
    path.moveTo(start.dx, start.dy + size * 0.5);
    path.lineTo(start.dx + size * 0.35, start.dy + size);
    path.lineTo(start.dx + size, start.dy);
    return path;
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
