import 'package:flutter/material.dart';

/// Утилита для адаптивных размеров текста
/// Автоматически масштабирует шрифты в зависимости от размера экрана
class ResponsiveText {
  /// Базовый масштаб шрифта в зависимости от ширины экрана
  static double _getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Для очень маленьких экранов (менее 320px)
    if (width < 320) {
      return 0.85;
    }
    // Для маленьких экранов (320-360px)
    else if (width < 360) {
      return 0.9;
    }
    // Для средних экранов (360-400px) - норма
    else if (width < 400) {
      return 1.0;
    }
    // Для больших экранов (400-600px)
    else if (width < 600) {
      return 1.1;
    }
    // Для планшетов (> 600px)
    else {
      return 1.2;
    }
  }

  /// Получить адаптивный размер шрифта
  static double getSize(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  /// Стиль для заголовков (большой жирный текст)
  static TextStyle heading(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 24),
      fontWeight: FontWeight.bold,
    );
  }

  /// Стиль для подзаголовков
  static TextStyle subHeading(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 18),
      fontWeight: FontWeight.w600,
    );
  }

  /// Стиль для основного текста
  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 14),
      fontWeight: FontWeight.normal,
    );
  }

  /// Стиль для маленького текста
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 12),
      fontWeight: FontWeight.normal,
    );
  }

  /// Стиль для очень маленького текста
  static TextStyle small(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 10),
      fontWeight: FontWeight.normal,
    );
  }

  /// Стиль для больших заголовков
  static TextStyle display(BuildContext context) {
    return TextStyle(
      fontSize: getSize(context, 32),
      fontWeight: FontWeight.bold,
    );
  }
}

/// Утилита для адаптивных отступов и размеров
class ResponsiveSpacing {
  /// Получить адаптивный отступ
  static double spacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;

    if (width < 320) {
      return baseSpacing * 0.8;
    } else if (width < 360) {
      return baseSpacing * 0.9;
    } else {
      return baseSpacing;
    }
  }

  /// Получить адаптивный размер иконки
  static double iconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;

    if (width < 320) {
      return baseSize * 0.85;
    } else if (width < 360) {
      return baseSize * 0.9;
    } else {
      return baseSize;
    }
  }
}



