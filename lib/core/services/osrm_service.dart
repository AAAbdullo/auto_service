import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../constants/route_types.dart';

/// Сервис для работы с OSRM (Open Source Routing Machine)
/// Бесплатная альтернатива для построения маршрутов
class OSRMService {
  // Публичные OSRM серверы
  static const String _baseUrl = 'https://router.project-osrm.org';
  
  /// Получить маршрут через OSRM
  static Future<RouteInfo?> getRouteInfo(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    try {
      final profile = _getOSRMProfile(routeType);
      final coordinates = '${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}';
      
      final uri = Uri.parse('$_baseUrl/route/v1/$profile/$coordinates?overview=false&steps=false');
      
      print('🛣️ OSRM Request: $uri');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      print('📡 OSRM Response Status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('❌ OSRM Error: ${response.statusCode} - ${response.body}');
        return _getFallbackRoute(startPoint, endPoint, routeType);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data['code'] != 'Ok' || data['routes'] == null || (data['routes'] as List).isEmpty) {
        print('❌ OSRM: No routes found');
        return _getFallbackRoute(startPoint, endPoint, routeType);
      }

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;
      
      print('✅ OSRM Route: ${(distance / 1000).toStringAsFixed(1)} км, ${(duration / 60).toStringAsFixed(0)} мин');
      
      String? transitInfo;
      switch (routeType) {
        case RouteType.walking:
          transitInfo = '🚶 Пешком (OSRM)';
          break;
        case RouteType.driving:
          transitInfo = '🚗 Автомобиль (OSRM)';
          break;
        case RouteType.transit:
          transitInfo = '🚌 Транспорт (приблизительно)';
          break;
      }

      return RouteInfo(
        type: routeType,
        distance: distance,
        duration: duration,
        transitInfo: transitInfo,
      );
    } catch (e) {
      print('❌ OSRM Exception: $e');
      return _getFallbackRoute(startPoint, endPoint, routeType);
    }
  }

  /// Получить детальный маршрут с геометрией
  static Future<OSRMRouteResult?> getDetailedRoute(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    try {
      final profile = _getOSRMProfile(routeType);
      final coordinates = '${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}';
      
      final uri = Uri.parse('$_baseUrl/route/v1/$profile/$coordinates?overview=full&geometries=geojson&steps=true');
      
      print('🗺️ OSRM Detailed Request: $profile');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data['code'] != 'Ok' || data['routes'] == null || (data['routes'] as List).isEmpty) {
        return null;
      }

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;
      
      // Извлекаем геометрию
      List<Point> points = [startPoint, endPoint];
      
      if (route.containsKey('geometry')) {
        final geometry = route['geometry'] as Map<String, dynamic>;
        if (geometry.containsKey('coordinates')) {
          final coords = geometry['coordinates'] as List;
          points = coords.map((coord) {
            final coordList = coord as List;
            return Point(
              latitude: (coordList[1] as num).toDouble(),
              longitude: (coordList[0] as num).toDouble(),
            );
          }).toList();
          print('✅ OSRM Geometry: ${points.length} points');
        }
      }

      // Извлекаем маневры из steps
      final List<OSRMManeuver> maneuvers = [];
      final legs = (route['legs'] as List?) ?? [];
      
      for (final leg in legs) {
        final legData = leg as Map<String, dynamic>;
        final steps = (legData['steps'] as List?) ?? [];
        
        for (final step in steps) {
          final stepData = step as Map<String, dynamic>;
          final maneuver = stepData['maneuver'] as Map<String, dynamic>?;
          
          if (maneuver != null) {
            final type = maneuver['type'] as String? ?? 'continue';
            final modifier = maneuver['modifier'] as String?;
            final location = maneuver['location'] as List?;
            
            if (location != null && location.length >= 2) {
              maneuvers.add(OSRMManeuver(
                type: type,
                modifier: modifier,
                location: Point(
                  latitude: (location[1] as num).toDouble(),
                  longitude: (location[0] as num).toDouble(),
                ),
              ));
            }
          }
        }
      }

      return OSRMRouteResult(
        points: points,
        distance: distance,
        duration: duration,
        maneuvers: maneuvers,
      );
    } catch (e) {
      print('❌ OSRM Detailed Exception: $e');
      return null;
    }
  }

  /// Получить профиль OSRM для типа маршрута
  static String _getOSRMProfile(RouteType routeType) {
    switch (routeType) {
      case RouteType.walking:
        return 'foot'; // Пешеходный профиль
      case RouteType.driving:
        return 'driving'; // Автомобильный профиль
      case RouteType.transit:
        return 'driving'; // Для транспорта используем автомобильный как базу
    }
  }

  /// Fallback расчет при недоступности OSRM
  static RouteInfo _getFallbackRoute(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) {
    final distance = _calculateDistance(startPoint, endPoint);
    
    double duration;
    String transitInfo;
    
    switch (routeType) {
      case RouteType.driving:
        final hour = DateTime.now().hour;
        double speed = 50; // км/ч базовая скорость
        
        if (hour >= 7 && hour <= 10 || hour >= 17 && hour <= 20) {
          speed = 30; // Час пик
        } else if (hour >= 22 || hour <= 6) {
          speed = 60; // Ночь
        }
        
        duration = distance / (speed / 3.6);
        transitInfo = '🚗 Автомобиль (приблизительно, ~${speed.toInt()} км/ч)';
        break;
        
      case RouteType.walking:
        duration = distance / (5 / 3.6); // 5 км/ч
        transitInfo = '🚶 Пешком (приблизительно, ~5 км/ч)';
        break;
        
      case RouteType.transit:
        duration = distance / (25 / 3.6) * 1.4; // 25 км/ч + 40% на ожидание
        transitInfo = '🚌 Транспорт (приблизительно, ~25 км/ч + ожидание)';
        break;
    }
    
    print('📍 Fallback OSRM: ${(distance / 1000).toStringAsFixed(1)} км, ${(duration / 60).toStringAsFixed(0)} мин');
    
    return RouteInfo(
      type: routeType,
      distance: distance,
      duration: duration,
      transitInfo: transitInfo,
    );
  }

  /// Вычислить расстояние между двумя точками (формула гаверсинуса)
  static double _calculateDistance(Point point1, Point point2) {
    const earthRadius = 6371000; // метры
    
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}

/// Результат детального маршрута от OSRM
class OSRMRouteResult {
  final List<Point> points;
  final double distance;
  final double duration;
  final List<OSRMManeuver> maneuvers;

  OSRMRouteResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.maneuvers,
  });
}

/// Маневр от OSRM
class OSRMManeuver {
  final String type;
  final String? modifier;
  final Point location;

  OSRMManeuver({
    required this.type,
    this.modifier,
    required this.location,
  });
}
