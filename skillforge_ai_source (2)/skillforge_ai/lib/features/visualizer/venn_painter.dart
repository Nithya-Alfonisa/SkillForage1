import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws two overlapping sets. INNER JOIN highlights only the intersection;
/// LEFT JOIN highlights the whole left set (including the intersection).
class VennPainter extends CustomPainter {
  VennPainter({
    required this.leftJoin,
    required this.progress,
    required this.leftColor,
    required this.rightColor,
    required this.highlight,
    required this.textColor,
  });

  final bool leftJoin;
  final double progress;
  final Color leftColor;
  final Color rightColor;
  final Color highlight;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.height * 0.34, size.width * 0.26);
    final cy = size.height * 0.46;
    final cx = size.width / 2;
    final dx = r * 0.62;
    final c1 = Offset(cx - dx, cy);
    final c2 = Offset(cx + dx, cy);

    final left = Path()..addOval(Rect.fromCircle(center: c1, radius: r));
    final right = Path()..addOval(Rect.fromCircle(center: c2, radius: r));
    final inter = Path.combine(PathOperation.intersect, left, right);

    canvas.drawPath(left, Paint()..color = leftColor.withOpacity(0.10));
    canvas.drawPath(right, Paint()..color = rightColor.withOpacity(0.10));
    if (leftJoin) {
      canvas.drawPath(
          left, Paint()..color = highlight.withOpacity(0.28 * progress));
    }
    canvas.drawPath(
        inter, Paint()..color = highlight.withOpacity(0.55 * progress));

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(left, stroke..color = leftColor);
    canvas.drawPath(right, stroke..color = rightColor);

    final labelStyle = TextStyle(
        color: textColor, fontSize: 13, fontWeight: FontWeight.w700);
    _text(canvas, 'Students', Offset(c1.dx - r * 0.45, cy), labelStyle);
    _text(canvas, 'Courses', Offset(c2.dx + r * 0.45, cy), labelStyle);
    _text(canvas, 'match', Offset(cx, cy), labelStyle.copyWith(fontSize: 12));
    _text(
      canvas,
      leftJoin ? 'All of Students + matches' : 'Only the overlap',
      Offset(cx, cy + r + 14),
      TextStyle(color: textColor, fontSize: 12),
    );
  }

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant VennPainter old) =>
      old.leftJoin != leftJoin ||
      old.progress != progress ||
      old.leftColor != leftColor ||
      old.rightColor != rightColor ||
      old.highlight != highlight ||
      old.textColor != textColor;
}
