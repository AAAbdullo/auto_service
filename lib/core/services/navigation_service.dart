import 'dart:async';
<<<<<<< HEAD
import 'dart:math' as math;
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
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

  // Для голосовых подсказок
  final TTSService _tts = TTSService();
  double _lastAnnouncedDistance = double.infinity;

  // Callback для обновления UI
  Function(NavigationState)? onNavigationUpdate;

  /// Начать навигацию
  Future<void> startNavigation({
    required RouteResult route,
    required Point destination,
    required Function(NavigationState) onUpdate,
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

    // Инициализация TTS
    await _tts.initialize();
    await _tts.announceNavigationStart(
      'пункт назначения',
      route.distanceKm,
      route.durationWithTrafficMinutes,
    );

    // Начать отслеживание позиции
    _startPositionTracking();

    debugPrint('🚀 Навигация начата');
    _notifyUpdate();
  }

  /// Остановить навигацию
  Future<void> stopNavigation() async {
    if (!_isNavigating) return;

    _isNavigating = false;
    _activeRoute = null;
    _destination = null;

    await _positionStream?.cancel();
    _positionStream = null;

    await _tts.announceNavigationCancelled();

    debugPrint('🛑 Навигация остановлена');
    _notifyUpdate();
  }

  /// Начать отслеживание позиции
  void _startPositionTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Обновлять каждые 5 метров
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
  void _onPositionUpdate(Position position) {
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

    // Проверить приближение к цели (используем расстояние по прямой)
    _checkApproaching(straightLineDistance);

    // Обновить UI
    _notifyUpdate();

    debugPrint(
      '📍 Позиция обновлена: скорость ${_currentSpeed.toStringAsFixed(1)} км/ч, '
      'осталось ${(_remainingDistance / 1000).toStringAsFixed(1)} км '
      '(по прямой: ${(straightLineDistance / 1000).toStringAsFixed(1)} км)',
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
  void _checkApproaching(double straightLineDistance) {
    // Озвучиваем на определенных расстояниях (используем расстояние по прямой)
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

    // Прибыли к цели (используем расстояние по прямой)
    if (straightLineDistance < 30) {
      _tts.announceNavigationComplete();
      stopNavigation();
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
    );
  }

  /// Получить параметры камеры для режима следования
  CameraPosition? getFollowingCameraPosition() {
    if (_currentPosition == null) return null;

    // Азимут (направление движения)
    double azimuth = 0.0;
<<<<<<< HEAD

    // Если есть предыдущая позиция и движемся - используем направление движения
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    if (_previousPosition != null && _currentSpeed > 1.0) {
      azimuth = Geolocator.bearingBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
<<<<<<< HEAD
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
=======
    } else if (_currentPosition!.heading > 0) {
      azimuth = _currentPosition!.heading;
    }

    return CameraPosition(
      target: Point(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
      zoom: 17.0, // Приближенный вид
      azimuth: azimuth, // Поворот карты по направлению движения
      tilt: 45.0, // Наклон для 3D вида (как в Яндекс Картах)
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    );
  }

  // Геттеры
  bool get isNavigating => _isNavigating;
  double get currentSpeed => _currentSpeed;
  double get remainingDistance => _remainingDistance;
  int get remainingTime => _remainingTime;
  Position? get currentPosition => _currentPosition;
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

  NavigationState({
    required this.isNavigating,
    required this.currentSpeed,
    required this.remainingDistance,
    required this.remainingTime,
    this.currentPosition,
    this.destination,
    this.route,
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
