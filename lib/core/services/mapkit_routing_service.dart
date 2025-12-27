import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:auto_service/core/services/yandex_router_api_service.dart';

// Экспортируем типы из yandex_router_api_service для обратной совместимости
export 'package:auto_service/core/services/yandex_router_api_service.dart'
    show RouteResult, RouteType;

/// Универсальный сервис маршрутизации с поддержкой всех типов транспорта
/// Использует HTTP API вместо нативного SDK для обхода MissingPluginException
class MapKitRoutingService {
  /// Тип маршрута
  static RouteType _currentRouteType = RouteType.driving;

  /// Установить тип маршрута
  static void setRouteType(RouteType type) {
    _currentRouteType = type;
    debugPrint('🔄 Тип маршрута изменен на: ${type.name}');
  }

  /// Получить текущий тип маршрута
  static RouteType get currentRouteType => _currentRouteType;

  /// Построение маршрута (автоматически выбирает нужный API)
  static Future<RouteResult?> buildRoute({
    required Point startPoint,
    required Point endPoint,
    RouteType? routeType,
  }) async {
    final type = routeType ?? _currentRouteType;

    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 ПОСТРОЕНИЕ МАРШРУТА: ${type.emoji} ${type.name}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint(
      '📍 Начальная точка: ${startPoint.latitude}, ${startPoint.longitude}',
    );
    debugPrint(
      '📍 Конечная точка: ${endPoint.latitude}, ${endPoint.longitude}',
    );

    // Проверяем расстояние
    final distance = _calculateDistance(
      startPoint.latitude,
      startPoint.longitude,
      endPoint.latitude,
      endPoint.longitude,
    );
    debugPrint('📏 Расстояние по прямой: ${distance.toStringAsFixed(1)} км');

    if (distance > 1000) {
      debugPrint(
        '⚠️  ВНИМАНИЕ: Расстояние слишком большое (${distance.toStringAsFixed(0)} км)',
      );
      debugPrint(
        '   Yandex MapKit может не построить маршрут на такое расстояние',
      );
    }

    try {
      switch (type) {
        case RouteType.driving:
          return await _buildDrivingRoute(startPoint, endPoint);
        case RouteType.walking:
          return await _buildWalkingRoute(startPoint, endPoint);
      }
    } catch (e) {
      debugPrint('❌ Ошибка построения маршрута: $e');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

  /// Построение автомобильного маршрута
  static Future<RouteResult?> _buildDrivingRoute(
    Point startPoint,
    Point endPoint,
  ) async {
    debugPrint('🚗 Построение автомобильного маршрута через HTTP API...');

    return await YandexRouterApiService.buildDrivingRoute(
      startPoint: startPoint,
      endPoint: endPoint,
    );
  }

  /// Построение пешеходного маршрута
  static Future<RouteResult?> _buildWalkingRoute(
    Point startPoint,
    Point endPoint,
  ) async {
    debugPrint('🚶 Построение пешеходного маршрута через HTTP API...');

    return await YandexRouterApiService.buildWalkingRoute(
      startPoint: startPoint,
      endPoint: endPoint,
    );
  }

  /// Вычисляет расстояние между двумя координатами (формула гаверсинусов)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // км
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
