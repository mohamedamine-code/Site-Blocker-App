import 'dart:math' as math;

import 'package:flutter/material.dart';

class HexGridBackground extends StatelessWidget {
  const HexGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HexGridPainter(
            lineColor: colors.outlineVariant.withValues(alpha: 0.32),
            glowColor: colors.primary.withValues(alpha: 0.08),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  _HexGridPainter({required this.lineColor, required this.glowColor});

  final Color lineColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 24.0;
    final rowHeight = math.sqrt(3) * radius;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;

    for (double y = -rowHeight; y < size.height + rowHeight; y += rowHeight) {
      final isOffsetRow = ((y / rowHeight).round() & 1) == 1;
      for (double x = -radius * 2; x < size.width + radius * 2; x += radius * 3) {
        final center = Offset(x + (isOffsetRow ? radius * 1.5 : 0), y);
        final hexPath = _hexagonPath(center, radius);
        canvas.drawPath(hexPath, linePaint);
      }
    }

    final glowRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(glowRect, glowPaint);
  }

  Path _hexagonPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.glowColor != glowColor;
  }
}
