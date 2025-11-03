import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Виджет навигационной стрелки с CustomPaint
class NavigationArrow extends StatelessWidget {
  final double heading; // направление в градусах (0-360)
  final double size;
  final Color color;
  final Color shadowColor;

  const NavigationArrow({
    super.key,
    required this.heading,
    this.size = 60.0,
    this.color = Colors.blue,
    this.shadowColor = Colors.black26,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * math.pi / 180.0,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NavigationArrowPainter(
          color: color,
          shadowColor: shadowColor,
        ),
      ),
    );
  }
}

class _NavigationArrowPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _NavigationArrowPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Тень
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final shadowPath = _createArrowPath(size, offset: const Offset(2, 2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Основная стрелка
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final arrowPath = _createArrowPath(size);
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.drawPath(arrowPath, strokePaint);

    // Центральная точка
    canvas.drawCircle(
      center,
      radius * 0.15,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  Path _createArrowPath(Size size, {Offset offset = Offset.zero}) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2) + offset;
    final radius = size.width / 2;

    // Стрелка направлена вверх (0 градусов)
    // Острие стрелки
    final tip = Offset(center.dx, center.dy - radius * 0.8);
    
    // Левое крыло
    final leftWing = Offset(center.dx - radius * 0.4, center.dy - radius * 0.2);
    
    // Правое крыло  
    final rightWing = Offset(center.dx + radius * 0.4, center.dy - radius * 0.2);
    
    // Левая сторона хвоста
    final leftTail = Offset(center.dx - radius * 0.25, center.dy + radius * 0.6);
    
    // Правая сторона хвоста
    final rightTail = Offset(center.dx + radius * 0.25, center.dy + radius * 0.6);

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(leftWing.dx, leftWing.dy);
    path.lineTo(leftTail.dx, leftTail.dy);
    path.lineTo(rightTail.dx, rightTail.dy);
    path.lineTo(rightWing.dx, rightWing.dy);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
