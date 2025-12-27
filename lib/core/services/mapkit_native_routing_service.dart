import 'package:flutter/foundation.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

/// Сервис для построения маршрутов через нативный Yandex MapKit SDK
/// Использует YandexDriving вместо HTTP API
class MapKitNativeRoutingService {
  /// Построить автомобильный маршрут через нативный SDK
  ///
  /// Возвращает список альтернативных маршрутов (до [routesCount])
  /// Включает информацию о пробках, дорожных событиях и времени в пути
  static Future<List<DrivingRoute>> buildDrivingRoute({
    required Point startPoint,
    required Point endPoint,
    int routesCount = 1,
  }) async {
    debugPrint('🚗 Построение автомобильного маршрута через нативный SDK...');
    debugPrint('📍 От: ${startPoint.latitude}, ${startPoint.longitude}');
    debugPrint('📍 До: ${endPoint.latitude}, ${endPoint.longitude}');

    try {
      // Создаём точки маршрута
      final requestPoints = [
        RequestPoint(
          point: startPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
        RequestPoint(
          point: endPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
      ];

      // Настройки построения маршрута
      final drivingOptions = DrivingOptions(
        initialAzimuth: null,
        routesCount: routesCount,
        avoidanceFlags: const DrivingAvoidanceFlags(),
      );

      // Запрашиваем маршруты
      final resultWithSession = await YandexDriving.requestRoutes(
        points: requestPoints,
        drivingOptions: drivingOptions,
      );

      final session = resultWithSession.$1;
      final result = await resultWithSession.$2;

      // Закрываем сессию
      await session.close();

      if (result.error != null) {
        debugPrint('❌ Ошибка: ${result.error}');
        return [];
      }

      if (result.routes == null || result.routes!.isEmpty) {
        debugPrint('❌ Маршруты не найдены');
        return [];
      }

      debugPrint('✅ Получено ${result.routes!.length} маршрутов');

      // Выводим информацию о каждом маршруте
      for (var i = 0; i < result.routes!.length; i++) {
        final route = result.routes![i];
        final metadata = route.metadata;
        debugPrint('📊 Маршрут ${i + 1}:');
        debugPrint('   Расстояние: ${metadata.weight.distance.text}');
        debugPrint('   Время: ${metadata.weight.time.text}');
        debugPrint('   С пробками: ${metadata.weight.timeWithTraffic.text}');
      }

      return result.routes!;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка построения автомобильного маршрута: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Построить пешеходный маршрут через нативный SDK
  ///
  /// Использует YandexBicycle для пешеходных маршрутов
  static Future<BicycleSessionResult?> buildWalkingRoute({
    required Point startPoint,
    required Point endPoint,
  }) async {
    debugPrint('🚶 Построение пешеходного маршрута через нативный SDK...');
    debugPrint('📍 От: ${startPoint.latitude}, ${startPoint.longitude}');
    debugPrint('📍 До: ${endPoint.latitude}, ${endPoint.longitude}');

    try {
      // Создаём точки маршрута
      final requestPoints = [
        RequestPoint(
          point: startPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
        RequestPoint(
          point: endPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
      ];

      // Запрашиваем пешеходный маршрут
      final resultWithSession = await YandexBicycle.requestRoutes(
        points: requestPoints,
        timeOptions: TimeOptions(departureTime: DateTime.now()),
        fitnessOptions: const FitnessOptions(
          avoidSteep: false,
          avoidStairs: false,
        ),
      );

      final session = resultWithSession.$1;
      final result = await resultWithSession.$2;

      // Закрываем сессию
      await session.close();

      if (result.error != null) {
        debugPrint('❌ Ошибка: ${result.error}');
        return null;
      }

      if (result.routes == null || result.routes!.isEmpty) {
        debugPrint('❌ Пешеходный маршрут не найден');
        return null;
      }

      final route = result.routes!.first;
      final metadata = route.metadata;
      debugPrint('✅ Пешеходный маршрут построен:');
      debugPrint('   Время: ${metadata.weight.time.text}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка построения пешеходного маршрута: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
