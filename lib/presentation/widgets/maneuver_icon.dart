import 'package:flutter/material.dart';

/// Виджет для отображения иконки маневра на основе типа и модификатора из Яндекс Router API
class ManeuverIcon extends StatelessWidget {
  final String type;
  final String? modifier;
  final double size;
  final Color color;

  const ManeuverIcon({
    super.key,
    required this.type,
    this.modifier,
    this.size = 24.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ManeuverPainter(type: type, modifier: modifier, color: color),
    );
  }
}

class _ManeuverPainter extends CustomPainter {
  final String type;
  final String? modifier;
  final Color color;

  _ManeuverPainter({required this.type, this.modifier, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case 'depart':
        _drawDepart(canvas, size, paint, fillPaint);
        break;
      case 'arrive':
        _drawArrive(canvas, size, paint, fillPaint);
        break;
      case 'turn':
        _drawTurn(canvas, size, paint, modifier);
        break;
      case 'roundabout':
        _drawRoundabout(canvas, size, paint, modifier);
        break;
      case 'merge':
        _drawMerge(canvas, size, paint, modifier);
        break;
      case 'fork':
        _drawFork(canvas, size, paint, modifier);
        break;
      case 'continue':
        _drawContinue(canvas, size, paint);
        break;
      default:
        _drawDefault(canvas, size, paint);
    }
  }

  void _drawDepart(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Стартовая точка - зелёный кружок
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 3, fillPaint..color = Colors.green);
    canvas.drawCircle(center, size.width / 3, paint..color = Colors.green);
  }

  void _drawArrive(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Финишный флажок
    final flagPole = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.1);

    final flag = Path()
      ..moveTo(size.width * 0.2, size.height * 0.1)
      ..lineTo(size.width * 0.7, size.height * 0.25)
      ..lineTo(size.width * 0.2, size.height * 0.4)
      ..close();

    canvas.drawPath(flagPole, paint..strokeWidth = 3);
    canvas.drawPath(flag, fillPaint..color = Colors.red);
    canvas.drawPath(flag, paint..color = Colors.red);
  }

  void _drawTurn(Canvas canvas, Size size, Paint paint, String? modifier) {
    final path = Path();

    switch (modifier) {
      case 'left':
        // Стрелка влево
        path.moveTo(size.width * 0.7, size.height * 0.5);
        path.lineTo(size.width * 0.3, size.height * 0.5);
        // Наконечник стрелки
        path.moveTo(size.width * 0.3, size.height * 0.5);
        path.lineTo(size.width * 0.4, size.height * 0.3);
        path.moveTo(size.width * 0.3, size.height * 0.5);
        path.lineTo(size.width * 0.4, size.height * 0.7);
        break;
      case 'right':
        // Стрелка вправо
        path.moveTo(size.width * 0.3, size.height * 0.5);
        path.lineTo(size.width * 0.7, size.height * 0.5);
        // Наконечник стрелки
        path.moveTo(size.width * 0.7, size.height * 0.5);
        path.lineTo(size.width * 0.6, size.height * 0.3);
        path.moveTo(size.width * 0.7, size.height * 0.5);
        path.lineTo(size.width * 0.6, size.height * 0.7);
        break;
      case 'slight_left':
        // Плавный поворот влево
        path.moveTo(size.width * 0.7, size.height * 0.7);
        path.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.3,
          size.width * 0.3,
          size.height * 0.3,
        );
        // Наконечник
        path.moveTo(size.width * 0.3, size.height * 0.3);
        path.lineTo(size.width * 0.4, size.height * 0.2);
        path.moveTo(size.width * 0.3, size.height * 0.3);
        path.lineTo(size.width * 0.4, size.height * 0.4);
        break;
      case 'slight_right':
        // Плавный поворот вправо
        path.moveTo(size.width * 0.3, size.height * 0.7);
        path.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.3,
          size.width * 0.7,
          size.height * 0.3,
        );
        // Наконечник
        path.moveTo(size.width * 0.7, size.height * 0.3);
        path.lineTo(size.width * 0.6, size.height * 0.2);
        path.moveTo(size.width * 0.7, size.height * 0.3);
        path.lineTo(size.width * 0.6, size.height * 0.4);
        break;
      case 'sharp_left':
        // Резкий поворот влево (почти разворот)
        path.moveTo(size.width * 0.7, size.height * 0.5);
        path.lineTo(size.width * 0.5, size.height * 0.5);
        path.lineTo(size.width * 0.5, size.height * 0.2);
        path.lineTo(size.width * 0.3, size.height * 0.2);
        // Наконечник
        path.moveTo(size.width * 0.3, size.height * 0.2);
        path.lineTo(size.width * 0.4, size.height * 0.1);
        path.moveTo(size.width * 0.3, size.height * 0.2);
        path.lineTo(size.width * 0.4, size.height * 0.3);
        break;
      case 'sharp_right':
        // Резкий поворот вправо
        path.moveTo(size.width * 0.3, size.height * 0.5);
        path.lineTo(size.width * 0.5, size.height * 0.5);
        path.lineTo(size.width * 0.5, size.height * 0.2);
        path.lineTo(size.width * 0.7, size.height * 0.2);
        // Наконечник
        path.moveTo(size.width * 0.7, size.height * 0.2);
        path.lineTo(size.width * 0.6, size.height * 0.1);
        path.moveTo(size.width * 0.7, size.height * 0.2);
        path.lineTo(size.width * 0.6, size.height * 0.3);
        break;
      case 'uturn':
        // Разворот
        final rect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.4),
          width: size.width * 0.4,
          height: size.height * 0.4,
        );
        path.addArc(rect, 0, 3.14159); // Полукруг
        // Наконечник
        path.moveTo(size.width * 0.3, size.height * 0.4);
        path.lineTo(size.width * 0.2, size.height * 0.3);
        path.moveTo(size.width * 0.3, size.height * 0.4);
        path.lineTo(size.width * 0.2, size.height * 0.5);
        break;
      default:
        // Прямо
        path.moveTo(size.width * 0.5, size.height * 0.8);
        path.lineTo(size.width * 0.5, size.height * 0.2);
        // Наконечник
        path.moveTo(size.width * 0.5, size.height * 0.2);
        path.lineTo(size.width * 0.4, size.height * 0.3);
        path.moveTo(size.width * 0.5, size.height * 0.2);
        path.lineTo(size.width * 0.6, size.height * 0.3);
    }

    canvas.drawPath(path, paint..strokeWidth = 3);
  }

  void _drawRoundabout(
    Canvas canvas,
    Size size,
    Paint paint,
    String? modifier,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Круг кольца
    canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);

    // Стрелка входа
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.5);
    // Наконечник входа
    path.moveTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.moveTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.6);

    // Стрелка выхода в зависимости от модификатора
    switch (modifier) {
      case 'right':
        path.moveTo(size.width * 0.5, size.height * 0.35);
        path.lineTo(size.width * 0.5, size.height * 0.1);
        path.moveTo(size.width * 0.5, size.height * 0.1);
        path.lineTo(size.width * 0.4, size.height * 0.15);
        path.moveTo(size.width * 0.5, size.height * 0.1);
        path.lineTo(size.width * 0.6, size.height * 0.15);
        break;
      case 'left':
        path.moveTo(size.width * 0.5, size.height * 0.65);
        path.lineTo(size.width * 0.5, size.height * 0.9);
        path.moveTo(size.width * 0.5, size.height * 0.9);
        path.lineTo(size.width * 0.4, size.height * 0.85);
        path.moveTo(size.width * 0.5, size.height * 0.9);
        path.lineTo(size.width * 0.6, size.height * 0.85);
        break;
      default:
        path.moveTo(size.width * 0.65, size.height * 0.5);
        path.lineTo(size.width * 0.9, size.height * 0.5);
        path.moveTo(size.width * 0.9, size.height * 0.5);
        path.lineTo(size.width * 0.85, size.height * 0.4);
        path.moveTo(size.width * 0.9, size.height * 0.5);
        path.lineTo(size.width * 0.85, size.height * 0.6);
    }

    canvas.drawPath(path, paint..strokeWidth = 2);
  }

  void _drawMerge(Canvas canvas, Size size, Paint paint, String? modifier) {
    final path = Path();

    // Основная дорога
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.5);

    // Въезжающая дорога
    if (modifier == 'left') {
      path.moveTo(size.width * 0.1, size.height * 0.2);
      path.lineTo(size.width * 0.6, size.height * 0.5);
    } else {
      path.moveTo(size.width * 0.1, size.height * 0.8);
      path.lineTo(size.width * 0.6, size.height * 0.5);
    }

    canvas.drawPath(path, paint..strokeWidth = 2);
  }

  void _drawFork(Canvas canvas, Size size, Paint paint, String? modifier) {
    final path = Path();

    // Основная дорога
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.5);

    // Развилка
    path.moveTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.2);
    path.moveTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.8);

    // Выделяем выбранное направление
    if (modifier == 'left') {
      // Стрелка на левую развилку
      path.moveTo(size.width * 0.85, size.height * 0.2);
      path.lineTo(size.width * 0.8, size.height * 0.15);
      path.moveTo(size.width * 0.85, size.height * 0.2);
      path.lineTo(size.width * 0.8, size.height * 0.25);
    } else if (modifier == 'right') {
      // Стрелка на правую развилку
      path.moveTo(size.width * 0.85, size.height * 0.8);
      path.lineTo(size.width * 0.8, size.height * 0.75);
      path.moveTo(size.width * 0.85, size.height * 0.8);
      path.lineTo(size.width * 0.8, size.height * 0.85);
    }

    canvas.drawPath(path, paint..strokeWidth = 2);
  }

  void _drawContinue(Canvas canvas, Size size, Paint paint) {
    // Прямая стрелка
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.2);
    // Наконечник
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.4, size.height * 0.3);
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.3);

    canvas.drawPath(path, paint..strokeWidth = 3);
  }

  void _drawDefault(Canvas canvas, Size size, Paint paint) {
    // Простая точка для неизвестных типов
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.width / 4,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
