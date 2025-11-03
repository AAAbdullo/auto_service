import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../constants/route_types.dart';
import 'osrm_service.dart';
import 'yandex_router_service.dart';

/// Гибридный сервис маршрутизации
/// Использует OSRM как основной + Яндекс Router API как fallback
class HybridRoutingService {
  
  /// Получить информацию о маршруте (пробует OSRM, потом Яндекс)
  static Future<RouteInfo?> getRouteInfo(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    print('🔄 Hybrid Routing: Trying OSRM first...');
    
    // Сначала пробуем OSRM (бесплатный и надежный)
    final osrmResult = await OSRMService.getRouteInfo(startPoint, endPoint, routeType);
    
    if (osrmResult != null && osrmResult.distance > 0) {
      print('✅ Hybrid: Using OSRM route');
      return osrmResult;
    }
    
    print('🔄 Hybrid: OSRM failed, trying Yandex Router API...');
    
    // Если OSRM не сработал, пробуем Яндекс Router API
    final yandexResult = await YandexRouterService.getRouteInfo(startPoint, endPoint, routeType);
    
    if (yandexResult != null && yandexResult.distance > 0) {
      print('✅ Hybrid: Using Yandex route');
      return yandexResult;
    }
    
    print('❌ Hybrid: Both services failed, no route available');
    return null;
  }

  /// Получить детальный маршрут с геометрией
  static Future<HybridRouteResult?> getDetailedRoute(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    print('🗺️ Hybrid Detailed: Trying OSRM first...');
    
    // Сначала пробуем OSRM
    final osrmResult = await OSRMService.getDetailedRoute(startPoint, endPoint, routeType);
    
    if (osrmResult != null && osrmResult.points.length > 2) {
      print('✅ Hybrid Detailed: Using OSRM geometry (${osrmResult.points.length} points)');
      return HybridRouteResult(
        points: osrmResult.points,
        distance: osrmResult.distance,
        duration: osrmResult.duration,
        maneuvers: osrmResult.maneuvers.map((m) => HybridManeuver(
          type: m.type,
          modifier: m.modifier,
          location: m.location,
        )).toList(),
        source: 'OSRM',
      );
    }
    
    print('🔄 Hybrid Detailed: OSRM failed, trying Yandex...');
    
    // Если OSRM не сработал, пробуем Яндекс
    final yandexResult = await YandexRouterService.getDetailedRoute(startPoint, endPoint, routeType);
    
    if (yandexResult != null && yandexResult.points.length > 2) {
      print('✅ Hybrid Detailed: Using Yandex geometry (${yandexResult.points.length} points)');
      return HybridRouteResult(
        points: yandexResult.points,
        distance: yandexResult.distance,
        duration: yandexResult.duration,
        maneuvers: yandexResult.maneuvers.map((m) => HybridManeuver(
          type: m.type,
          modifier: m.modifier,
          location: m.point,
        )).toList(),
        source: 'Yandex',
      );
    }
    
    print('❌ Hybrid Detailed: Both services failed');
    return null;
  }

  /// Получить список доступных маршрутов для всех типов транспорта
  static Future<List<RouteInfo>> getAvailableRoutes(
    Point startPoint,
    Point endPoint,
  ) async {
    print('🚗🚶🚌 Getting routes for all transport types...');
    
    final routes = <RouteInfo>[];
    
    // Параллельно запрашиваем все типы маршрутов
    final futures = [
      getRouteInfo(startPoint, endPoint, RouteType.driving),
      getRouteInfo(startPoint, endPoint, RouteType.walking),
      getRouteInfo(startPoint, endPoint, RouteType.transit),
    ];
    
    final results = await Future.wait(futures);
    
    for (final result in results) {
      if (result != null) {
        routes.add(result);
      }
    }
    
    // Сортируем по времени (самый быстрый первый)
    routes.sort((a, b) => a.duration.compareTo(b.duration));
    
    print('✅ Found ${routes.length} available routes');
    return routes;
  }

  /// Получить рекомендуемый тип маршрута на основе расстояния
  static RouteType getRecommendedRouteType(double distanceKm) {
    if (distanceKm < 1.5) {
      return RouteType.walking; // До 1.5 км - пешком
    } else if (distanceKm < 15) {
      return RouteType.driving; // До 15 км - на машине
    } else {
      return RouteType.transit; // Больше 15 км - на транспорте
    }
  }
}

/// Результат гибридного маршрута
class HybridRouteResult {
  final List<Point> points;
  final double distance;
  final double duration;
  final List<HybridManeuver> maneuvers;
  final String source; // 'OSRM' или 'Yandex'

  HybridRouteResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.maneuvers,
    required this.source,
  });
}

/// Универсальный маневр для гибридного сервиса
class HybridManeuver {
  final String type;
  final String? modifier;
  final Point location;

  HybridManeuver({
    required this.type,
    this.modifier,
    required this.location,
  });
}
