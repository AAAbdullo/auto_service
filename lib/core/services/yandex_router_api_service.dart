import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_service/core/config/yandex_config.dart';

/// Сервис для построения маршрутов через HTTP API Yandex Router
/// Использует REST API вместо нативного SDK для обхода MissingPluginException
class YandexRouterApiService {
  /// Построить автомобильный маршрут через HTTP API
  static Future<RouteResult?> buildDrivingRoute({
    required Point startPoint,
    required Point endPoint,
  }) async {
    debugPrint('🌐 Построение маршрута через Yandex Router HTTP API...');

    try {
      final url = Uri.parse(
        'https://api.routing.yandex.net/v2/route?'
        'apikey=${YandexConfig.routingApiKey}&'
        'waypoints=${startPoint.longitude},${startPoint.latitude}|${endPoint.longitude},${endPoint.latitude}&'
        'mode=driving',
      );

      debugPrint('📡 Запрос: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Route API timeout');
            },
          );

      debugPrint('📦 Ответ: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Ошибка API: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['route'] == null || data['route'].isEmpty) {
        debugPrint('❌ Маршрут не найден');
        return null;
      }

      final route = data['route'][0];
      final legs = route['legs'] as List;

      // Собираем все точки геометрии
      final List<Point> geometryPoints = [];
      for (var leg in legs) {
        final steps = leg['steps'] as List;
        for (var step in steps) {
          final polyline = step['polyline'];
          if (polyline != null && polyline['points'] != null) {
            for (var point in polyline['points']) {
              geometryPoints.add(
                Point(latitude: point[1], longitude: point[0]),
              );
            }
          }
        }
      }

      // Получаем метрики
      final distance =
          (route['distance'] as num).toDouble() / 1000; // метры -> км
      final duration = ((route['duration'] as num).toDouble() / 60)
          .toInt(); // секунды -> минуты
      final durationWithTraffic = route['duration_in_traffic'] != null
          ? ((route['duration_in_traffic'] as num).toDouble() / 60).toInt()
          : duration;

      debugPrint('✅ Маршрут построен через API!');
      debugPrint('📏 Расстояние: ${distance.toStringAsFixed(1)} км');
      debugPrint('⏱️  Время: $duration мин');
      debugPrint('🚦 С пробками: $durationWithTraffic мин');
      debugPrint('📍 Точек геометрии: ${geometryPoints.length}');

      return RouteResult(
        type: RouteType.driving,
        geometryPoints: geometryPoints,
        distanceKm: distance,
        durationMinutes: duration,
        durationWithTrafficMinutes: durationWithTraffic,
      );
    } on TimeoutException catch (e) {
      debugPrint('⏰ Таймаут запроса: $e');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка HTTP API: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }

  /// Построить пешеходный маршрут через HTTP API
  static Future<RouteResult?> buildWalkingRoute({
    required Point startPoint,
    required Point endPoint,
  }) async {
    debugPrint('🌐 Построение пешеходного маршрута через API...');

    try {
      final url = Uri.parse(
        'https://api.routing.yandex.net/v2/route?'
        'apikey=${YandexConfig.routingApiKey}&'
        'waypoints=${startPoint.longitude},${startPoint.latitude}|${endPoint.longitude},${endPoint.latitude}&'
        'mode=pedestrian',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('❌ Ошибка API: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['route'] == null || data['route'].isEmpty) {
        return null;
      }

      final route = data['route'][0];
      final legs = route['legs'] as List;

      final List<Point> geometryPoints = [];
      for (var leg in legs) {
        final steps = leg['steps'] as List;
        for (var step in steps) {
          final polyline = step['polyline'];
          if (polyline != null && polyline['points'] != null) {
            for (var point in polyline['points']) {
              geometryPoints.add(
                Point(latitude: point[1], longitude: point[0]),
              );
            }
          }
        }
      }

      final distance = (route['distance'] as num).toDouble() / 1000;
      final duration = ((route['duration'] as num).toDouble() / 60).toInt();

      debugPrint('✅ Пешеходный маршрут построен!');
      debugPrint('📏 Расстояние: ${distance.toStringAsFixed(1)} км');
      debugPrint('⏱️  Время: $duration мин');

      return RouteResult(
        type: RouteType.walking,
        geometryPoints: geometryPoints,
        distanceKm: distance,
        durationMinutes: duration,
        durationWithTrafficMinutes: duration,
      );
    } catch (e) {
      debugPrint('❌ Ошибка: $e');
      return null;
    }
  }
}

/// Результат построения маршрута
class RouteResult {
  final RouteType type;
  final List<Point> geometryPoints;
  final double distanceKm;
  final int durationMinutes;
  final int durationWithTrafficMinutes;

  // НОВЫЕ поля для нативного SDK
  final String? routeId; // URI маршрута
  final bool isAlternative; // Альтернативный маршрут

  RouteResult({
    required this.type,
    required this.geometryPoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.durationWithTrafficMinutes,
    this.routeId,
    this.isAlternative = false,
  });

  /// Создать RouteResult из нативного DrivingRoute
  factory RouteResult.fromDrivingRoute(
    DrivingRoute route, {
    bool isAlternative = false,
  }) {
    final metadata = route.metadata;
    final geometry = route.geometry;

    return RouteResult(
      type: RouteType.driving,
      geometryPoints: geometry.points,
      distanceKm: metadata.weight.distance.value! / 1000,
      durationMinutes: (metadata.weight.time.value! / 60).round(),
      durationWithTrafficMinutes: (metadata.weight.timeWithTraffic.value! / 60)
          .round(),
      routeId: null, // URI не доступен в текущей версии API
      isAlternative: isAlternative,
    );
  }

  /// Создать RouteResult из нативного MasstransitRoute (пешеходный/велосипедный)
  factory RouteResult.fromMasstransitRoute(MasstransitRoute route) {
    final metadata = route.metadata;
    final geometry = route.geometry;

    return RouteResult(
      type: RouteType.walking,
      geometryPoints: geometry.points,
      distanceKm: metadata.weight.walkingDistance.value! / 1000,
      durationMinutes: (metadata.weight.time.value! / 60).round(),
      durationWithTrafficMinutes: (metadata.weight.time.value! / 60).round(),
      routeId: null,
      isAlternative: false,
    );
  }

  /// Форматированное расстояние
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} м';
    }
    return '${distanceKm.toStringAsFixed(1)} км';
  }

  /// Форматированное время в пути
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes мин';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '$hours ч $minutes мин';
  }

  /// Форматированное время с учётом пробок
  String get formattedDurationWithTraffic {
    if (durationWithTrafficMinutes < 60) {
      return '$durationWithTrafficMinutes мин';
    }
    final hours = durationWithTrafficMinutes ~/ 60;
    final minutes = durationWithTrafficMinutes % 60;
    return '$hours ч $minutes мин';
  }
}

/// Тип маршрута
enum RouteType {
  driving('Автомобиль', '🚗'),
  walking('Пешком', '🚶');

  final String name;
  final String emoji;
  const RouteType(this.name, this.emoji);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
