import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../constants/route_types.dart';
import '../config/yandex_config.dart';

/// Сервис для работы с Яндекс Router API
/// Использует специальный ключ для маршрутизации (отличается от MapKit ключа)
class YandexRouterService {
  static String get _baseUrl => YandexConfig.routingBaseUrl;
  static String get _apiKey => YandexConfig.routingApiKey;

  /// Получить информацию о маршруте
  static Future<RouteInfo?> getRouteInfo(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    try {
      final waypoints = '${startPoint.latitude},${startPoint.longitude}|${endPoint.latitude},${endPoint.longitude}';
      final tempInfo = RouteInfo(type: routeType, distance: 0, duration: 0);
      final mode = tempInfo.yandexMode;
      final additionalParams = tempInfo.yandexParameters;
      
      // Строим URL с дополнительными параметрами для оптимального маршрута
      final queryParams = {
        'waypoints': waypoints,
        'mode': mode,
        'apikey': _apiKey,
        ...additionalParams,
      };
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      print('🔍 Yandex API Request: $uri');
      print('📋 Route mode: $mode, params: $additionalParams');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      print('📡 Yandex API Response Status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('❌ Yandex API Error: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 401) {
          print('🔑 API ключ отклонен. Используем fallback расчет.');
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      print('📋 Yandex API Response Data: ${data.toString().substring(0, 500)}...');
      
      // Проверяем успешность ответа (может быть разные форматы)
      if (data.containsKey('error')) {
        print('❌ Yandex API Error in response: ${data['error']}');
        return null;
      }
      
      if (data.containsKey('status') && data['status'] != 'success') {
        print('❌ Yandex API Status not success: ${data['status']}');
        return null;
      }

      // Пытаемся извлечь данные маршрута из разных возможных структур
      Map<String, dynamic>? route;
      
      if (data.containsKey('route')) {
        route = data['route'] as Map<String, dynamic>?;
        print('✅ Found route in data.route');
      } else if (data.containsKey('data') && data['data'].containsKey('route')) {
        route = data['data']['route'] as Map<String, dynamic>?;
        print('✅ Found route in data.data.route');
      } else if (data.containsKey('routes') && (data['routes'] as List).isNotEmpty) {
        route = (data['routes'] as List).first as Map<String, dynamic>?;
        print('✅ Found route in data.routes[0]');
      } else {
        print('❌ No route found in response structure');
        print('📋 Available keys: ${data.keys.toList()}');
        return null;
      }

      if (route == null) {
        print('❌ Route is null after extraction');
        return null;
      }

      final distance = (route['distance'] as num?)?.toDouble() ?? 
                      (route['length'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 
                      (route['time'] as num?)?.toDouble() ?? 0.0;
      
      print('📏 Route distance: ${distance}m, duration: ${duration}s');

      // Применяем корректировки времени в зависимости от типа маршрута
      double adjustedDuration = duration;
      String? transitInfo;

      switch (routeType) {
        case RouteType.driving:
          // Для машины: добавляем коэффициент пробок
          final hour = DateTime.now().hour;
          if (hour >= 7 && hour <= 10 || hour >= 17 && hour <= 20) {
            adjustedDuration *= 1.8; // Час пик
          } else if (hour >= 11 && hour <= 16) {
            adjustedDuration *= 1.3; // Обычное время
          } else {
            adjustedDuration *= 1.1; // Ночь/раннее утро
          }
          break;
          
        case RouteType.walking:
          // Для пешехода время обычно точное
          transitInfo = '🚶 Пешком';
          break;
          
        case RouteType.transit:
          // Для общественного транспорта добавляем время ожидания
          adjustedDuration *= 1.5;
          transitInfo = '🚌 Общественный транспорт';
          break;
      }

      return RouteInfo(
        type: routeType,
        distance: distance,
        duration: adjustedDuration,
        transitInfo: transitInfo,
      );
    } catch (e) {
      print('❌ Yandex API Exception: $e');
      // Fallback: вычисляем приблизительное расстояние и время
      return _createFallbackRoute(startPoint, endPoint, routeType);
    }
  }

  /// Создать fallback маршрут при недоступности API
  static RouteInfo _createFallbackRoute(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) {
    // Вычисляем приблизительное расстояние по прямой (формула гаверсинуса)
    final distance = _calculateDistance(startPoint, endPoint);
    
    // Приблизительное время в зависимости от типа маршрута
    double duration;
    String? transitInfo;
    
    switch (routeType) {
      case RouteType.driving:
        // Для автомобиля: учитываем время суток и пробки
        final hour = DateTime.now().hour;
        double baseSpeed = 50; // км/ч базовая скорость
        
        if (hour >= 7 && hour <= 10 || hour >= 17 && hour <= 20) {
          baseSpeed = 25; // Час пик - медленнее
        } else if (hour >= 22 || hour <= 6) {
          baseSpeed = 60; // Ночь - быстрее
        }
        
        duration = distance / (baseSpeed / 3.6); // м/с в секунды
        transitInfo = '🚗 Авто (без API, ~${baseSpeed.toInt()} км/ч)';
        break;
        
      case RouteType.walking:
        // Для пешехода: стандартная скорость 5 км/ч
        duration = distance / (5 / 3.6); // 5 км/ч в м/с
        transitInfo = '🚶 Пешком (без API, ~5 км/ч)';
        break;
        
      case RouteType.transit:
        // Для общественного транспорта: учитываем ожидание и пересадки
        double baseSpeed = 20; // км/ч средняя скорость с учетом остановок
        duration = distance / (baseSpeed / 3.6); // базовое время
        duration *= 1.5; // +50% на ожидание и пересадки
        
        transitInfo = '🚌 Транспорт (без API, ~${baseSpeed.toInt()} км/ч + ожидание)';
        break;
    }
    
    print('📍 Fallback route: ${(distance / 1000).toStringAsFixed(1)} км, ${(duration / 60).toStringAsFixed(0)} мин');
    
    return RouteInfo(
      type: routeType,
      distance: distance,
      duration: duration,
      transitInfo: transitInfo,
    );
  }

  /// Вычислить расстояние между двумя точками (формула гаверсинуса)
  static double _calculateDistance(Point point1, Point point2) {
    const double earthRadius = 6371000; // Радиус Земли в метрах
    
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

  /// Декодировать encoded polyline (алгоритм Google Maps)
  static List<Point> _decodePolyline(String encoded) {
    List<Point> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(Point(
        latitude: lat / 1e5,
        longitude: lng / 1e5,
      ));
    }

    return points;
  }

  /// Получить детальный маршрут с геометрией
  static Future<YandexRouteResult?> getDetailedRoute(
    Point startPoint,
    Point endPoint,
    RouteType routeType,
  ) async {
    try {
      final waypoints = '${startPoint.latitude},${startPoint.longitude}|${endPoint.latitude},${endPoint.longitude}';
      final tempInfo = RouteInfo(type: routeType, distance: 0, duration: 0);
      final mode = tempInfo.yandexMode;
      final additionalParams = tempInfo.yandexParameters;
      
      // Строим URL с дополнительными параметрами для детального маршрута
      final queryParams = {
        'waypoints': waypoints,
        'mode': mode,
        'apikey': _apiKey,
        ...additionalParams,
      };
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      print('🗺️ Detailed route request: $mode with params: $additionalParams');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Проверяем успешность ответа
      if (data.containsKey('error') || 
          (data.containsKey('status') && data['status'] != 'success')) {
        return null;
      }

      // Пытаемся извлечь данные маршрута
      Map<String, dynamic>? route;
      
      if (data.containsKey('route')) {
        route = data['route'] as Map<String, dynamic>?;
      } else if (data.containsKey('data') && data['data'].containsKey('route')) {
        route = data['data']['route'] as Map<String, dynamic>?;
      } else if (data.containsKey('routes') && (data['routes'] as List).isNotEmpty) {
        route = (data['routes'] as List).first as Map<String, dynamic>?;
      }

      if (route == null) {
        print('⚠️ No detailed route found, using simple line between points');
        // Если нет детальной геометрии, создаем простую линию между точками
        return YandexRouteResult(
          points: [startPoint, endPoint],
          maneuvers: [],
          distance: 0.0,
          duration: 0.0,
        );
      }

      final distance = (route['distance'] as num?)?.toDouble() ?? 
                      (route['length'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 
                      (route['time'] as num?)?.toDouble() ?? 0.0;
      
      // Пытаемся извлечь геометрию маршрута
      List<Point> points = [startPoint, endPoint]; // Базовая линия
      final List<YandexManeuver> maneuvers = [];
      
      print('🗺️ Searching for route geometry...');
      
      // Ищем геометрию в разных возможных местах
      bool geometryFound = false;
      
      // Вариант 1: geometry.coordinates (GeoJSON формат)
      if (route.containsKey('geometry')) {
        final geometry = route['geometry'];
        if (geometry is Map && geometry.containsKey('coordinates')) {
          final coords = geometry['coordinates'] as List?;
          if (coords != null) {
            points = coords.map((coord) {
              final coordList = coord as List;
              return Point(
                latitude: (coordList[1] as num).toDouble(),
                longitude: (coordList[0] as num).toDouble(),
              );
            }).toList();
            geometryFound = true;
            print('✅ Found geometry in route.geometry.coordinates (${points.length} points)');
          }
        }
      }
      
      // Вариант 2: encoded polyline (как в Google Maps)
      if (!geometryFound && route.containsKey('overview_polyline')) {
        final polyline = route['overview_polyline'];
        if (polyline is Map && polyline.containsKey('points')) {
          final encodedPolyline = polyline['points'] as String?;
          if (encodedPolyline != null) {
            points = _decodePolyline(encodedPolyline);
            geometryFound = true;
            print('✅ Found geometry in encoded polyline (${points.length} points)');
          }
        }
      }
      
      // Вариант 3: legs с steps (детальная геометрия)
      if (!geometryFound) {
        final legs = (route['legs'] as List?) ?? [];
        final allPoints = <Point>[];
        
        for (final leg in legs) {
          final legData = leg as Map<String, dynamic>;
          final steps = (legData['steps'] as List?) ?? [];
          
          for (final step in steps) {
            final stepData = step as Map<String, dynamic>;
            
            // Ищем геометрию в step
            if (stepData.containsKey('geometry')) {
              final stepGeometry = stepData['geometry'];
              if (stepGeometry is Map && stepGeometry.containsKey('coordinates')) {
                final coords = stepGeometry['coordinates'] as List?;
                if (coords != null) {
                  final stepPoints = coords.map((coord) {
                    final coordList = coord as List;
                    return Point(
                      latitude: (coordList[1] as num).toDouble(),
                      longitude: (coordList[0] as num).toDouble(),
                    );
                  }).toList();
                  allPoints.addAll(stepPoints);
                }
              }
            }
          }
        }
        
        if (allPoints.isNotEmpty) {
          points = allPoints;
          geometryFound = true;
          print('✅ Found geometry in legs/steps (${points.length} points)');
        }
      }
      
      if (!geometryFound) {
        print('⚠️ No detailed geometry found, using straight line');
      }
      
      // Извлекаем маневры если есть
      final legs = (route['legs'] as List?) ?? [];
      for (final leg in legs) {
        final legData = leg as Map<String, dynamic>;
        final steps = (legData['steps'] as List?) ?? [];
        
        for (final step in steps) {
          final stepData = step as Map<String, dynamic>;
          
          // Извлекаем информацию о маневрах
          final maneuver = stepData['maneuver'] as Map<String, dynamic>?;
          if (maneuver != null) {
            final location = maneuver['location'] as List?;
            if (location != null && location.length >= 2) {
              maneuvers.add(YandexManeuver(
                type: maneuver['instruction'] as String? ?? 
                      maneuver['type'] as String? ?? 'continue',
                modifier: maneuver['modifier'] as String?,
                name: stepData['name'] as String?,
                point: Point(
                  latitude: (location[1] as num).toDouble(),
                  longitude: (location[0] as num).toDouble(),
                ),
                distance: (stepData['distance'] as num?)?.toDouble() ?? 0.0,
              ));
            }
          }
        }
      }

      return YandexRouteResult(
        points: points,
        maneuvers: maneuvers,
        distance: distance,
        duration: duration,
      );
    } catch (e) {
      // В случае ошибки возвращаем простую линию между точками
      return YandexRouteResult(
        points: [startPoint, endPoint],
        maneuvers: [],
        distance: 0.0,
        duration: 0.0,
      );
    }
  }
}

/// Результат запроса маршрута от Яндекс API
class YandexRouteResult {
  final List<Point> points;
  final List<YandexManeuver> maneuvers;
  final double distance;
  final double duration;

  YandexRouteResult({
    required this.points,
    required this.maneuvers,
    required this.distance,
    required this.duration,
  });
}

/// Информация о маневре от Яндекс API
class YandexManeuver {
  final String type;
  final String? modifier;
  final String? name;
  final Point point;
  final double distance;

  YandexManeuver({
    required this.type,
    this.modifier,
    this.name,
    required this.point,
    required this.distance,
  });
}
