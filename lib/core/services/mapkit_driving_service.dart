import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Сервис для построения маршрутов через нативный Yandex MapKit Driving Router
/// Использует full-версию SDK с подробным логированием
class MapKitDrivingService {
  /// Инициализация сервиса (для совместимости, фактически не требуется)
  static void initialize() {
    debugPrint('✅ MapKit Driving Service готов к использованию');
  }

  /// Построение маршрута между двумя точками
  static Future<DrivingResultWithSession?> buildRoute({
    required Point startPoint,
    required Point endPoint,
    List<Point>? viaPoints,
    int routesCount = 1,
  }) async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚗 НАЧАЛО ПОСТРОЕНИЯ МАРШРУТА');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint(
      '📍 Начальная точка: ${startPoint.latitude}, ${startPoint.longitude}',
    );
    debugPrint(
      '📍 Конечная точка: ${endPoint.latitude}, ${endPoint.longitude}',
    );

    // Проверяем расстояние между точками
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
      debugPrint('   Проверьте координаты точек!');
    }

    if (viaPoints != null && viaPoints.isNotEmpty) {
      debugPrint('📍 Промежуточные точки: ${viaPoints.length}');
      for (var i = 0; i < viaPoints.length; i++) {
        debugPrint(
          '   ${i + 1}. ${viaPoints[i].latitude}, ${viaPoints[i].longitude}',
        );
      }
    }

    try {
      // Создаем список точек маршрута
      final List<RequestPoint> requestPoints = [];

      // Начальная точка (wayPoint)
      requestPoints.add(
        RequestPoint(
          point: startPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
      );

      // Промежуточные точки (viaPoint)
      if (viaPoints != null) {
        for (final point in viaPoints) {
          requestPoints.add(
            RequestPoint(
              point: point,
              requestPointType: RequestPointType.viaPoint,
            ),
          );
        }
      }

      // Конечная точка (wayPoint)
      requestPoints.add(
        RequestPoint(
          point: endPoint,
          requestPointType: RequestPointType.wayPoint,
        ),
      );

      debugPrint('✅ Точки маршрута подготовлены: ${requestPoints.length} шт.');

      // Настройки маршрута
      final drivingOptions = DrivingOptions(
        initialAzimuth: null,
        routesCount: routesCount,
      );

      debugPrint('✅ DrivingOptions созданы:');
      debugPrint('   - Количество маршрутов: $routesCount');
      debugPrint('');
      debugPrint('🔄 Отправка запроса в Yandex MapKit...');

      // Создаем Completer для async/await работы
      final completer = Completer<DrivingResultWithSession?>();

      // Отправляем запрос
      final resultWithSession = await YandexDriving.requestRoutes(
        points: requestPoints,
        drivingOptions: drivingOptions,
      );

      final session = resultWithSession.$1;
      final resultFuture = resultWithSession.$2;

      debugPrint('✅ Сессия создана, ожидаем результат...');

      // Ждем результат с таймаутом
      try {
        final result = await resultFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('');
            debugPrint('⏱️ ТАЙМАУТ: Превышено время ожидания (10 сек)');
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            session.cancel();
            throw TimeoutException('Route request timeout');
          },
        );

        _handleDrivingResult(result, completer);
        final finalResult = await completer.future;

        // Закрываем сессию после получения результата
        session.close();

        return finalResult;
      } catch (e) {
        session.cancel();
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ КРИТИЧЕСКАЯ ОШИБКА при построении маршрута:');
      debugPrint('   Тип ошибки: ${e.runtimeType}');
      debugPrint('   Сообщение: $e');
      debugPrint('');
      debugPrint('📚 Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

  /// Обработка результата построения маршрута
  static void _handleDrivingResult(
    DrivingSessionResult result,
    Completer<DrivingResultWithSession?> completer,
  ) {
    debugPrint('');
    debugPrint('📥 ПОЛУЧЕН ОТВЕТ ОТ YANDEX MAPKIT');

    if (result.error != null) {
      debugPrint('❌ ОШИБКА ОТ СЕРВЕРА:');
      debugPrint('   ${result.error}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      completer.complete(null);
      return;
    }

    if (result.routes == null || result.routes!.isEmpty) {
      debugPrint('⚠️ Маршруты не найдены (пустой список)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      completer.complete(null);
      return;
    }

    final routes = result.routes!;
    debugPrint('✅ МАРШРУТЫ УСПЕШНО ПОЛУЧЕНЫ: ${routes.length} шт.');
    debugPrint('');

    // Обрабатываем каждый маршрут
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final metadata = route.metadata;

      debugPrint('═══════════════════════════════════════════');
      debugPrint('📊 МАРШРУТ #${i + 1}:');
      debugPrint('═══════════════════════════════════════════');

      // Дистанция
      final distanceValue = metadata.weight.distance.value ?? 0.0;
      final distanceKm = (distanceValue / 1000).toStringAsFixed(2);
      debugPrint('📏 Расстояние: $distanceKm км');

      // Время в пути (без пробок)
      final timeValue = metadata.weight.time.value ?? 0.0;
      final durationMin = (timeValue / 60).toInt();
      final hours = durationMin ~/ 60;
      final minutes = durationMin % 60;
      final durationStr = hours > 0 ? '$hours ч $minutes мин' : '$minutes мин';
      debugPrint('⏱️  Время (без пробок): $durationStr');

      // Время в пути (с пробками)
      final trafficValue = metadata.weight.timeWithTraffic.value ?? timeValue;
      final durationTrafficMin = (trafficValue / 60).toInt();
      final hoursTraffic = durationTrafficMin ~/ 60;
      final minutesTraffic = durationTrafficMin % 60;
      final durationTrafficStr = hoursTraffic > 0
          ? '$hoursTraffic ч $minutesTraffic мин'
          : '$minutesTraffic мин';
      debugPrint('🚦 Время (с пробками): $durationTrafficStr');

      // Геометрия маршрута
      final geometry = route.geometry;
      debugPrint('📍 Точек в геометрии: ${geometry.points.length}');

      // Первая и последняя точки
      if (geometry.points.isNotEmpty) {
        final firstPoint = geometry.points.first;
        final lastPoint = geometry.points.last;
        debugPrint(
          '   Начало: ${firstPoint.latitude.toStringAsFixed(6)}, ${firstPoint.longitude.toStringAsFixed(6)}',
        );
        debugPrint(
          '   Конец:  ${lastPoint.latitude.toStringAsFixed(6)}, ${lastPoint.longitude.toStringAsFixed(6)}',
        );
      }

      debugPrint('═══════════════════════════════════════════');
    }

    debugPrint('');
    debugPrint('✅ МАРШРУТ УСПЕШНО ПОСТРОЕН!');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    completer.complete(
      DrivingResultWithSession(routes: routes, session: result),
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

/// Результат построения маршрута вместе с сессией
class DrivingResultWithSession {
  final List<DrivingRoute> routes;
  final DrivingSessionResult session;

  DrivingResultWithSession({required this.routes, required this.session});

  /// Получить первый (оптимальный) маршрут
  DrivingRoute get primaryRoute => routes.first;

  /// Получить все точки геометрии первого маршрута
  List<Point> get geometryPoints => primaryRoute.geometry.points;

  /// Получить метаданные первого маршрута
  DrivingSectionMetadata get metadata => primaryRoute.metadata;

  /// Расстояние в метрах
  double get distanceMeters => metadata.weight.distance.value ?? 0.0;

  /// Расстояние в километрах
  double get distanceKm => distanceMeters / 1000;

  /// Время в пути без пробок (в секундах)
  double get durationSeconds => metadata.weight.time.value ?? 0.0;

  /// Время в пути с пробками (в секундах)
  double get durationWithTrafficSeconds =>
      metadata.weight.timeWithTraffic.value ?? durationSeconds;

  /// Время в пути без пробок (в минутах)
  int get durationMinutes => (durationSeconds / 60).round();

  /// Время в пути с пробками (в минутах)
  int get durationWithTrafficMinutes =>
      (durationWithTrafficSeconds / 60).round();
}
