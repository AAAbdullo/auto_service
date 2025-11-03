import 'package:flutter/material.dart';

/// Типы маршрутов для построения
enum RouteType {
  walking, // Пешком
  driving, // На машине
  transit, // На общественном транспорте
}

/// Информация о маршруте
class RouteInfo {
  final RouteType type;
  final double distance; // в метрах
  final double duration; // в секундах
  final String? transitInfo; // Информация о транспорте (для transit)

  RouteInfo({
    required this.type,
    required this.distance,
    required this.duration,
    this.transitInfo,
  });

  /// Получить расстояние в удобном формате
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toInt()} м';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} км';
    }
  }

  /// Получить время в удобном формате
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours ч $remainingMinutes мин';
    }
  }

  /// Получить иконку для типа маршрута
  IconData get icon {
    switch (type) {
      case RouteType.walking:
        return Icons.directions_walk;
      case RouteType.driving:
        return Icons.directions_car;
      case RouteType.transit:
        return Icons.directions_bus;
    }
  }

  /// Получить название типа маршрута
  String get name {
    switch (type) {
      case RouteType.walking:
        return 'Пешком';
      case RouteType.driving:
        return 'На машине';
      case RouteType.transit:
        return 'Транспорт';
    }
  }

  /// Получить режим для Яндекс Router API
  /// Поддерживаемые режимы:
  /// - driving: легковой автомобиль (по умолчанию)
  /// - walking: пешеход
  /// - transit: общественный транспорт
  /// - truck: грузовой автомобиль (будущее расширение)
  String get yandexMode {
    switch (type) {
      case RouteType.walking:
        return 'walking';
      case RouteType.driving:
        return 'driving';
      case RouteType.transit:
        return 'transit';
    }
  }

  /// Получить дополнительные параметры для Яндекс Router API
  Map<String, String> get yandexParameters {
    final params = <String, String>{};
    
    switch (type) {
      case RouteType.driving:
        // Для автомобиля: учитываем пробки в реальном времени
        params['traffic'] = 'realtime';
        break;
        
      case RouteType.walking:
        // Для пешехода: кратчайший путь
        params['avoid_tolls'] = 'false';
        break;
        
      case RouteType.transit:
        // Для общественного транспорта: учитываем расписание
        params['traffic'] = 'realtime';
        // Можно добавить время отправления
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        params['departure_time'] = now.toString();
        break;
    }
    
    return params;
  }

  /// Получить цвет для типа маршрута
  Color get color {
    switch (type) {
      case RouteType.walking:
        return Colors.green;
      case RouteType.driving:
        return Colors.blue;
      case RouteType.transit:
        return Colors.orange;
    }
  }
}
