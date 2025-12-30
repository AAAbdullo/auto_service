import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_service/core/services/mapkit_routing_service.dart';
import 'package:auto_service/core/services/tts_service.dart';

/// Сервис для управления навигацией в реальном времени
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Состояние навигации
  bool _isNavigating = false;
  RouteResult? _activeRoute;
  Point? _destination;

  // Отслеживание позиции
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  Position? _previousPosition;

  // Метрики навигации
  double _currentSpeed = 0.0; // км/ч
  double _remainingDistance = 0.0; // метры
  int _remainingTime = 0; // минуты
  double _totalDistance = 0.0; // метры
  List<Point> _remainingRoutePoints = []; // Оставшиеся точки маршрута

  // Для голосовых подсказок
  final TTSService _tts = TTSService();
  double _lastAnnouncedDistance = double.infinity;

  // Callback для обновления UI
  Function(NavigationState)? onNavigationUpdate;
  // Callback для очистки маршрута при прибытии
  Function()? onArrivalClearRoute;

  // TTS enabled state
  bool _ttsEnabled = true;

  /// Начать навигацию
  Future<void> startNavigation({
    required RouteResult route,
    required Point destination,
    required Function(NavigationState) onUpdate,
    Function()? onArrival,
    bool ttsEnabled = true,
  }) async {
    if (_isNavigating) {
      await stopNavigation();
    }

    _isNavigating = true;
    _activeRoute = route;
    _destination = destination;
    _totalDistance = route.distanceKm * 1000;
    _remainingDistance = _totalDistance;
    _remainingTime = route.durationWithTrafficMinutes;
    onNavigationUpdate = onUpdate;
    onArrivalClearRoute = onArrival;
    _ttsEnabled = ttsEnabled;

    // Инициализация TTS только если включено
    if (_ttsEnabled) {
      await _tts.initialize();
      await _tts.announceNavigationStart(
        'пункт назначения',
        route.distanceKm,
        route.durationWithTrafficMinutes,
      );
    }

    // Начать отслеживание позиции
    _startPositionTracking();

    debugPrint('🚀 Навигация начата');
    _notifyUpdate();
  }

  /// Остановить навигацию
  Future<void> stopNavigation({bool arrivedAtDestination = false}) async {
    if (!_isNavigating) return;

    _isNavigating = false;
    _activeRoute = null;
    _destination = null;

    await _positionStream?.cancel();
    _positionStream = null;

    // Объявление отмены только если TTS включен
    if (!arrivedAtDestination && _ttsEnabled) {
      await _tts.announceNavigationCancelled();
    }

    // Если прибыли к цели, вызываем callback для очистки маршрута
    if (arrivedAtDestination && onArrivalClearRoute != null) {
      onArrivalClearRoute!();
    }

    debugPrint('🛑 Навигация остановлена');
    _notifyUpdate();
  }

  /// Начать отслеживание позиции
  void _startPositionTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Обновлять каждый метр для моментального стирания
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _onPositionUpdate(position);
          },
          onError: (error) {
            debugPrint('❌ Ошибка отслеживания позиции: $error');
          },
        );
  }

  /// Обработка обновления позиции
  Future<void> _onPositionUpdate(Position position) async {
    if (!_isNavigating || _destination == null) return;

    _previousPosition = _currentPosition;
    _currentPosition = position;

    // Рассчитать скорость
    if (_previousPosition != null) {
      _currentSpeed = _calculateSpeed(_previousPosition!, position);
    } else {
      _currentSpeed = position.speed * 3.6; // м/с -> км/ч
    }

    // Рассчитать расстояние по прямой до цели (для проверки приближения)
    final straightLineDistance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    // Рассчитать оставшееся расстояние и время на основе прогресса
    if (_activeRoute != null && _totalDistance > 0) {
      // Вычисляем прогресс как отношение пройденного расстояния к общему
      // Используем расстояние по прямой для оценки прогресса
      final initialStraightDistance = Geolocator.distanceBetween(
        _activeRoute!.geometryPoints.first.latitude,
        _activeRoute!.geometryPoints.first.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );

      // Прогресс от 0 до 1
      final progress =
          (initialStraightDistance - straightLineDistance) /
          initialStraightDistance;
      final clampedProgress = progress.clamp(0.0, 1.0);

      // Оставшееся расстояние по маршруту
      _remainingDistance = _totalDistance * (1.0 - clampedProgress);

      // Оставшееся время
      final elapsedMinutes =
          (_activeRoute!.durationWithTrafficMinutes * clampedProgress).round();
      _remainingTime =
          _activeRoute!.durationWithTrafficMinutes - elapsedMinutes;
      if (_remainingTime < 0) _remainingTime = 0;
    } else if (_currentSpeed > 5) {
      // Fallback: использовать расстояние по прямой и скорость
      _remainingDistance = straightLineDistance;
      _remainingTime = (_remainingDistance / 1000 / _currentSpeed * 60).round();
    } else {
      // Если стоим на месте, используем расстояние по прямой
      _remainingDistance = straightLineDistance;
    }

    // Обновить оставшиеся точки маршрута (обрезать пройденную часть)
    _updateRemainingRoutePoints(position);

    // Проверить приближение к цели (используем расстояние по прямой)
    await _checkApproaching(straightLineDistance);

    // Обновить UI
    _notifyUpdate();

    debugPrint(
      '📍 Позиция обновлена: скорость ${_currentSpeed.toStringAsFixed(1)} км/ч, '
      'осталось ${(_remainingDistance / 1000).toStringAsFixed(1)} км '
      '(по прямой: ${(straightLineDistance / 1000).toStringAsFixed(1)} км)',
    );
  }

  /// Обновить оставшиеся точки маршрута (обрезать пройденную часть)
  void _updateRemainingRoutePoints(Position currentPosition) {
    if (_activeRoute == null || _activeRoute!.geometryPoints.isEmpty) {
      _remainingRoutePoints = [];
      return;
    }

    final allPoints = _activeRoute!.geometryPoints;
    final userPoint = Point(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
    );

    // Найти ближайшую точку маршрута к текущей позиции пользователя
    int closestPointIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < allPoints.length; i++) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        allPoints[i].latitude,
        allPoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // Оставляем только точки от ближайшей до конца маршрута
    // Добавляем текущую позицию пользователя как первую точку
    _remainingRoutePoints = [
      userPoint,
      ...allPoints.sublist(closestPointIndex),
    ];

    debugPrint(
      '🗺️ Обновлены точки маршрута: ${_remainingRoutePoints.length} из ${allPoints.length} (обрезано $closestPointIndex точек)',
    );
  }

  /// Рассчитать скорость между двумя позициями
  double _calculateSpeed(Position prev, Position current) {
    final distance = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      current.latitude,
      current.longitude,
    );

    final timeDiff = current.timestamp.difference(prev.timestamp).inSeconds;
    if (timeDiff == 0) return 0.0;

    final speedMs = distance / timeDiff;
    return speedMs * 3.6; // м/с -> км/ч
  }

  /// Проверить приближение к цели и озвучить
  Future<void> _checkApproaching(double straightLineDistance) async {
    // Озвучиваем на определенных расстояниях только если TTS включен
    if (_ttsEnabled) {
      if (straightLineDistance < 50 && _lastAnnouncedDistance >= 50) {
        _tts.announceApproaching(straightLineDistance);
        _lastAnnouncedDistance = straightLineDistance;
      } else if (straightLineDistance < 100 && _lastAnnouncedDistance >= 100) {
        _tts.announceApproaching(straightLineDistance);
        _lastAnnouncedDistance = straightLineDistance;
      } else if (straightLineDistance < 200 && _lastAnnouncedDistance >= 200) {
        _tts.announceApproaching(straightLineDistance);
        _lastAnnouncedDistance = straightLineDistance;
      } else if (straightLineDistance < 500 && _lastAnnouncedDistance >= 500) {
        _tts.announceApproaching(straightLineDistance);
        _lastAnnouncedDistance = straightLineDistance;
      }
    }

    // Прибыли к цели (используем расстояние по прямой)
    if (straightLineDistance < 30) {
      if (_ttsEnabled) {
        _tts.announceNavigationComplete();
      }
      // Передаем флаг, что навигация завершена автоматически (прибыли к цели)
      await stopNavigation(arrivedAtDestination: true);
    }
  }

  /// Уведомить об обновлении
  void _notifyUpdate() {
    if (onNavigationUpdate != null) {
      onNavigationUpdate!(getCurrentState());
    }
  }

  /// Получить текущее состояние навигации
  NavigationState getCurrentState() {
    return NavigationState(
      isNavigating: _isNavigating,
      currentSpeed: _currentSpeed,
      remainingDistance: _remainingDistance,
      remainingTime: _remainingTime,
      currentPosition: _currentPosition,
      destination: _destination,
      route: _activeRoute,
      remainingRoutePoints: _remainingRoutePoints,
    );
  }

  /// Получить параметры камеры для режима следования
  CameraPosition? getFollowingCameraPosition() {
    if (_currentPosition == null) return null;

    // Азимут (направление движения)
    double azimuth = 0.0;

    // Если есть предыдущая позиция и движемся - используем направление движения
    if (_previousPosition != null && _currentSpeed > 1.0) {
      azimuth = Geolocator.bearingBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
    // Если только начали навигацию - используем направление к первой точке маршрута
    else if (_activeRoute != null && _activeRoute!.geometryPoints.length > 1) {
      azimuth = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _activeRoute!.geometryPoints[1].latitude,
        _activeRoute!.geometryPoints[1].longitude,
      );
    }
    // Fallback - используем heading из GPS
    else if (_currentPosition!.heading > 0) {
      azimuth = _currentPosition!.heading;
    }

    // Смещаем точку фокуса вперед по направлению движения
    // Это создает эффект "камера позади стрелки"
    final offsetDistance = 0.0015; // ~150 метров вперед
    final azimuthRad = azimuth * 3.14159 / 180.0;

    final targetLat =
        _currentPosition!.latitude + (offsetDistance * math.cos(azimuthRad));
    final targetLon =
        _currentPosition!.longitude + (offsetDistance * math.sin(azimuthRad));

    return CameraPosition(
      target: Point(latitude: targetLat, longitude: targetLon),
      zoom: 17.0, // Приближенный вид
      azimuth: azimuth, // Поворот карты по направлению движения
      tilt: 60.0, // Увеличенный наклон для более сильного 3D эффекта
    );
  }

  // Геттеры
  bool get isNavigating => _isNavigating;
  double get currentSpeed => _currentSpeed;
  double get remainingDistance => _remainingDistance;
  int get remainingTime => _remainingTime;
  Position? get currentPosition => _currentPosition;

  /// Обновить состояние TTS во время навигации
  void setTTSEnabled(bool enabled) {
    _ttsEnabled = enabled;
    if (!enabled) {
      _tts.stop(); // Остановить текущее воспроизведение
    }
    debugPrint('🔊 TTS ${enabled ? "включен" : "выключен"}');
  }
}

/// Состояние навигации
class NavigationState {
  final bool isNavigating;
  final double currentSpeed; // км/ч
  final double remainingDistance; // метры
  final int remainingTime; // минуты
  final Position? currentPosition;
  final Point? destination;
  final RouteResult? route;
  final List<Point> remainingRoutePoints; // Оставшиеся точки маршрута

  NavigationState({
    required this.isNavigating,
    required this.currentSpeed,
    required this.remainingDistance,
    required this.remainingTime,
    this.currentPosition,
    this.destination,
    this.route,
    this.remainingRoutePoints = const [],
  });

  String get formattedSpeed => '${currentSpeed.toStringAsFixed(0)} км/ч';

  String get formattedDistance {
    if (remainingDistance < 1000) {
      return '${remainingDistance.toStringAsFixed(0)} м';
    }
    return '${(remainingDistance / 1000).toStringAsFixed(1)} км';
  }

  String get formattedTime {
    if (remainingTime < 60) {
      return '$remainingTime мин';
    }
    final hours = remainingTime ~/ 60;
    final minutes = remainingTime % 60;
    return '$hours ч $minutes мин';
  }
}
