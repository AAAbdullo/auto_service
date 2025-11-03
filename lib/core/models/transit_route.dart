import 'package:yandex_mapkit/yandex_mapkit.dart';

/// Модель остановки общественного транспорта
class TransitStop {
  final String id;
  final String name;
  final Point location;
  final Duration waitTime; // Среднее время ожидания

  TransitStop({
    required this.id,
    required this.name,
    required this.location,
    required this.waitTime,
  });
}

/// Модель маршрута общественного транспорта
class TransitRoute {
  final String number; // Номер маршрута (например, "12", "45А", "М1")
  final String type; // Тип: bus, trolleybus, metro, tram
  final List<TransitStop> stops; // Остановки по порядку
  final String color; // Цвет линии на карте
  final Duration averageInterval; // Интервал движения

  TransitRoute({
    required this.number,
    required this.type,
    required this.stops,
    required this.color,
    required this.averageInterval,
  });

  String get icon {
    switch (type) {
      case 'metro':
        return '🚇';
      case 'tram':
        return '🚊';
      case 'trolleybus':
        return '🚎';
      case 'bus':
      default:
        return '🚌';
    }
  }

  String get typeName {
    switch (type) {
      case 'metro':
        return 'Метро';
      case 'tram':
        return 'Трамвай';
      case 'trolleybus':
        return 'Троллейбус';
      case 'bus':
      default:
        return 'Автобус';
    }
  }
}

/// Сегмент маршрута (часть общего пути)
class RouteSegment {
  final String type; // walk, transit, transfer
  final Point? startPoint;
  final Point? endPoint;
  final double distance; // в метрах
  final double duration; // в секундах
  final TransitRoute? transitRoute; // null для пешеходных участков
  final TransitStop? boardingStop; // Где сесть
  final TransitStop? alightingStop; // Где выйти
  final String instruction; // Текстовая инструкция

  RouteSegment({
    required this.type,
    this.startPoint,
    this.endPoint,
    required this.distance,
    required this.duration,
    this.transitRoute,
    this.boardingStop,
    this.alightingStop,
    required this.instruction,
  });

  String get icon {
    switch (type) {
      case 'walk':
        return '🚶';
      case 'transfer':
        return '🔄';
      case 'transit':
        return transitRoute?.icon ?? '🚌';
      default:
        return '•';
    }
  }
}

/// Полный мультимодальный маршрут
class MultimodalRoute {
  final List<RouteSegment> segments;
  final double totalDistance;
  final double totalDuration;
  final int transferCount;

  MultimodalRoute({
    required this.segments,
    required this.totalDistance,
    required this.totalDuration,
    required this.transferCount,
  });

  String get summary {
    final hours = (totalDuration / 3600).floor();
    final minutes = ((totalDuration % 3600) / 60).ceil();
    final km = (totalDistance / 1000).toStringAsFixed(1);

    if (hours > 0) {
      return '$hours ч $minutes мин • $km км';
    } else {
      return '$minutes мин • $km км';
    }
  }
}







