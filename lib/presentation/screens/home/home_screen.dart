import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:auto_service/presentation/providers/theme_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/models/gas_station_model.dart';
import 'package:auto_service/presentation/widgets/common/loading_overlay.dart';
import 'package:auto_service/presentation/widgets/custom_search_bar.dart';
import 'package:auto_service/presentation/widgets/dialogs/location_permission_dialog.dart';
import 'package:auto_service/presentation/widgets/route_type_selector.dart';
import 'package:auto_service/presentation/widgets/maneuver_icon.dart';
import 'package:auto_service/core/constants/route_types.dart';
import 'package:auto_service/core/utils/debouncer.dart';
import 'package:auto_service/core/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_service/data/datasources/demo_services_data.dart';
import 'package:auto_service/data/datasources/demo_gas_stations_data.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:auto_service/core/services/hybrid_routing_service.dart';
import 'package:auto_service/core/services/voice_service.dart';

// Простейшая модель маневра из Яндекс Router API
class _ManeuverInfo {
  final String type; // e.g., turn, arrive, depart, roundabout
  final String? modifier; // e.g., right, left, slight_right
  final String? name; // street name
  final Point point; // место маневра
  final double distance; // дистанция участка шага, м
  _ManeuverInfo({
    required this.type,
    required this.point,
    required this.distance,
    this.modifier,
    this.name,
  });
}

class HomeScreen extends StatefulWidget {
  final double? targetLatitude;
  final double? targetLongitude;
  const HomeScreen({super.key, this.targetLatitude, this.targetLongitude});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  YandexMapController? _mapController;
  bool _isLoadingLocation = false;
  List<AutoServiceModel> _allServices = [];
  List<AutoServiceModel> _filteredServices = [];
  List<GasStationModel> _allGasStations = [];
  List<GasStationModel> _filteredGasStations = [];
  // Навигация по GPS
  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;
  double _speedKmh = 0.0;
  String _movementType = '';
  double _remainingDistance = 0.0; // Оставшееся расстояние в метрах
  double _remainingTime = 0.0; // Оставшееся время в секундах
  List<Point> _originalRoutePoints = []; // Оригинальный маршрут
  List<Point> _remainingRoutePoints = []; // Оставшаяся часть маршрута
  double? _lastHeading; // Направление движения
  double? _currentHeading; // Текущее направление для плавного поворота
  // Цель текущего маршрута и контроль пере-расчета
  Point? _destinationPoint; // Конечная точка активного маршрута
  DateTime? _lastRerouteAt; // Время последнего перерасчета
  Timer? _periodicRerouteTimer; // Таймер для периодического обновления маршрута

  // Типы маршрутов и информация
  List<RouteInfo> _availableRoutes = [];
  RouteInfo? _currentRouteInfo;

  // Кэш иконок из ассетов (если есть)
  BitmapDescriptor? _serviceAssetIcon;
  BitmapDescriptor? _gasAssetIcon;
  // Убрали _currentLocationAssetIcon и _navigationArrowIcon - используем встроенный индикатор Яндекс MapKit

  // Переключатель между автосервисами и заправками
  // false = автосервисы, true = заправки
  bool _showGasStations = false;

  Point? _currentPosition;
  double _selectedRating = 0.0;
  String? _selectedCategory;
  String _searchQuery = '';

  final List<MapObject> _mapObjects = [];
  PolylineMapObject? _routePolyline;
  bool _isUpdatingMapObjects = false;
  StreamSubscription<Position>? _positionSubscription;
  double _currentZoom = 12.0;

  static const double _walkThresholdKmh = 3.0;

  // Подсказки маневров
  List<_ManeuverInfo> _maneuvers = [];
  int _nextManeuverIndex = 0;
  double? _distanceToNextManeuver; // м
  bool _voiceEnabled = true;

  // Фиксированная стрелка убрана - используем только стрелку на карте
  // Последние параметры камеры для троттлинга follow
  Point? _lastCameraPoint;
  double? _lastCameraAzimuth;
  DateTime? _lastCameraFollowAt;

  // Показывали ли уже маршрут целиком (fit bounds)
  bool _didFitRouteOnce = false;

  // Последняя локаль приложения для синхронизации TTS
  String? _lastLocaleCode;

  // Ограничение скорости (км/ч), передаваемое Яндекс API (если доступно)
  int? _speedLimitKmh;
  // Дебаунс, чтобы не озвучивать превышение слишком часто
  DateTime? _lastOverspeedHintAt;

  // Оптимизация: кэш последней позиции для предотвращения лишних обновлений
  Point? _lastUpdatedPosition;
  DateTime? _lastMapUpdate;
  DateTime? _lastNavigationUpdate; // Для дебаунсинга обновлений навигации

  // Дебаунсер для поиска
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  // Кэш созданных маркеров
  final Map<String, PlacemarkMapObject> _cachedMarkers = {};
  // Включать ли фолбэк прямой линией, если некорректно работает маршрутизация

  // Проверяем, нужно ли обновлять карту
  bool _shouldUpdateMap(Point newPosition) {
    // Если первое обновление - обновляем
    if (_lastUpdatedPosition == null || _lastMapUpdate == null) {
      return true;
    }

    // Если идет навигация - обновляем чаще
    if (_isNavigating) {
      return true;
    }

    // Вычисляем расстояние от последней обновленной позиции
    final distance = Geolocator.distanceBetween(
      _lastUpdatedPosition!.latitude,
      _lastUpdatedPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // Обновляем только если переместились минимум на 20 метров
    // ИЛИ прошло минимум 5 секунд
    final timeSinceLastUpdate = DateTime.now().difference(_lastMapUpdate!);
    return distance > 20 || timeSinceLastUpdate.inSeconds > 5;
  }

  // Обновляем прогресс по маневрам: расстояние до следующего и автоматический переход к следующему
  void _updateNextManeuverProgress(Point userPoint) {
    if (_maneuvers.isEmpty || _nextManeuverIndex >= _maneuvers.length) {
      _distanceToNextManeuver = null;
      return;
    }
    final next = _maneuvers[_nextManeuverIndex];
    final d = Geolocator.distanceBetween(
      userPoint.latitude,
      userPoint.longitude,
      next.point.latitude,
      next.point.longitude,
    );
    _distanceToNextManeuver = d;

    // Порог срабатывания маневра: ближе для пешком, дальше для авто
    final trigger = (_movementType == 'walking'.tr()) ? 12.0 : 25.0;
    if (d <= trigger) {
      // Короткая голосовая подсказка (заглушка)
      _maybeSpeakManeuver(next);
      // Переходим к следующему маневру
      if (_nextManeuverIndex < _maneuvers.length - 1) {
        _nextManeuverIndex++;
      } else {
        // Последний маневр — почти прибытие
      }
    }
  }

  // Голосовая подсказка через Google TTS
  void _maybeSpeakManeuver(_ManeuverInfo m) {
    if (!_voiceEnabled) return;
    try {
      // Используем готовые фразы для маневров
      final phrase = NavigationPhrases.getManeuverPhrase(m.type, m.modifier);

      // Добавляем расстояние если есть
      String fullPhrase = phrase;
      if (_distanceToNextManeuver != null && _distanceToNextManeuver! > 10) {
        final distancePhrase = NavigationPhrases.getDistancePhrase(
          _distanceToNextManeuver!,
        );
        fullPhrase = '$phrase $distancePhrase';
      }

      debugPrint('🔊 Озвучиваем маневр: $fullPhrase');
      VoiceService().speak(fullPhrase);
    } catch (e) {
      debugPrint('❌ Ошибка озвучки маневра: $e');
    }
  }

  String _formatManeuverText(_ManeuverInfo m, {bool preview = false}) {
    final dir = switch (m.modifier) {
      'right' => 'direction_right'.tr(),
      'left' => 'direction_left'.tr(),
      'slight_right' => 'direction_slight_right'.tr(),
      'slight_left' => 'direction_slight_left'.tr(),
      'uturn' => 'direction_uturn'.tr(),
      'straight' => 'direction_straight'.tr(),
      _ => 'direction_straight'.tr(),
    };
    final road = (m.name != null && m.name!.isNotEmpty) ? ' на ${m.name}' : '';
    final action = switch (m.type) {
      'arrive' => 'maneuver_arrive'.tr(),
      'depart' => 'maneuver_depart'.tr(),
      'roundabout' => 'maneuver_roundabout'.tr(),
      _ => '${'maneuver_turn'.tr()} $dir$road',
    };
    if (preview && m.type == 'arrive') return 'maneuver_arriving_soon'.tr();
    return action;
  }

  @override
  void initState() {
    super.initState();
    // Предзагрузка ассетов маркеров: делает вероятность того, что иконки
    // не отрисуются при первом запуске минимальной. Выполняется после
    // первого рендера, чтобы rootBundle был готов.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _ensureMarkerAssetsLoaded();
        if (mounted) {
          // Обновим объекты на карте — это добавит маркеры, если ассеты загрузились
          _updateMapObjects();
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка предзагрузки иконок маркеров: $e');
      }
    });
    _loadNearbyServices();
    _loadGasStations();
    // НЕ устанавливаем фейковое местоположение - ждем реального GPS
    // Автоматически определяем местоположение при запуске
    _determinePosition();

    // Инициализируем менеджер уведомлений и голосовую озвучку после первого рендера
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationManager();
      _initVoiceService();
      // Начальная синхронизация языка TTS с локалью приложения
      final localeCode = context.locale.toString();
      _lastLocaleCode = localeCode;
      VoiceService().syncLanguageByLocale(localeCode);
    });

    // Подписываемся на обновления позиции
    // Используем оптимальные настройки для реальных устройств
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // Обновляем каждые 15 метров
      // Убираем timeLimit - он вызывает таймауты на реальных устройствах
    );
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) {
            final newPosition = Point(
              latitude: pos.latitude,
              longitude: pos.longitude,
            );

            // Оптимизация: обновляем карту только если позиция значительно изменилась
            // или прошло достаточно времени
            final shouldUpdate = _shouldUpdateMap(newPosition);

            _currentPosition = newPosition;

            if (shouldUpdate) {
              debugPrint(
                '📍 GPS обновлен: (${pos.latitude}, ${pos.longitude}) точность: ${pos.accuracy}м',
              );
              _lastUpdatedPosition = newPosition;
              _lastMapUpdate = DateTime.now();
              _updateMapObjects();
            }
          },
          onError: (error) {
            debugPrint('⚠️ GPS stream error (не критично): $error');
            // Не прерываем работу при ошибках GPS - продолжаем с текущей позицией
          },
        );

    // Слушаем изменения темы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _setMapTheme(themeProvider.isDarkMode);
      // Обновляем карту после загрузки всех данных
      _updateMapObjects();
    });

    // Если переданы координаты для построения маршрута
    if (widget.targetLatitude != null && widget.targetLongitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildRoute(widget.targetLatitude!, widget.targetLongitude!);
      });
    }
  }

  // Яндекс Router API: строим маршрут через Яндекс API и рисуем полилинию
  /// Получить информацию о маршруте через Яндекс Router API
  Future<RouteInfo?> _fetchRouteInfo(
    Point destinationPoint,
    RouteType routeType,
  ) async {
    try {
      if (_currentPosition == null) return null;

      return await HybridRoutingService.getRouteInfo(
        _currentPosition!,
        destinationPoint,
        routeType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Применить выбранный маршрут
  Future<void> _applySelectedRoute(
    Point destinationPoint,
    RouteInfo routeInfo,
  ) async {
    try {
      if (_currentPosition == null) return;

      // Получаем детальный маршрут через гибридный сервис
      final routeResult = await HybridRoutingService.getDetailedRoute(
        _currentPosition!,
        destinationPoint,
        routeInfo.type,
      );

      if (routeResult == null || routeResult.points.isEmpty) return;

      // Сохраняем оригинальные точки маршрута
      _originalRoutePoints = List.from(routeResult.points);
      _remainingRoutePoints = List.from(routeResult.points);

      // Конвертируем маневры гибридного сервиса в локальный формат
      final maneuvers = routeResult.maneuvers
          .map(
            (hybridManeuver) => _ManeuverInfo(
              type: hybridManeuver.type,
              modifier: hybridManeuver.modifier,
              name: null, // Имя улицы пока не поддерживается
              point: hybridManeuver.location,
              distance: 0.0, // Расстояние пока не поддерживается
            ),
          )
          .toList();

      print(
        '🎯 Using ${routeResult.source} route with ${maneuvers.length} maneuvers',
      );

      // Голосовое уведомление о построении маршрута
      if (_voiceEnabled) {
        VoiceService().speak(NavigationPhrases.routeCalculated);
      }

      setState(() {
        _currentRouteInfo = routeInfo;
        _routePolyline = PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: Polyline(points: routeResult.points),
          strokeColor: routeInfo.color,
          strokeWidth: 6.0,
        );
        _maneuvers = maneuvers;
        _nextManeuverIndex = 0;
        _distanceToNextManeuver = null;
        _didFitRouteOnce = false; // разрешим один раз показать весь маршрут
      });
      _updateMapObjects();

      // 📹 Плавно показваем весь маршрут ТОЛЬКО один раз и только когда не в навигации
      if (!_isNavigating && !_didFitRouteOnce) {
        _didFitRouteOnce = true;
        _moveCameraToShowFullRoute(routeResult.points);
      }
    } catch (e) {
      // Игнорируем ошибки применения маршрута
    }
  }

  /// Построить маршрут через Яндекс API
  Future<bool> _tryBuildRouteViaYandex(Point destinationPoint) async {
    try {
      // Получаем все типы маршрутов
      await _fetchAllRouteTypes(destinationPoint);

      // Применяем маршрут по умолчанию (driving)
      if (_availableRoutes.isNotEmpty) {
        final defaultRoute = _availableRoutes.firstWhere(
          (r) => r.type == RouteType.driving,
          orElse: () => _availableRoutes.first,
        );
        await _applySelectedRoute(destinationPoint, defaultRoute);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Получить все типы маршрутов
  Future<void> _fetchAllRouteTypes(Point destinationPoint) async {
    final futures = <Future<RouteInfo?>>[];

    // Получаем маршруты для всех типов
    for (final routeType in RouteType.values) {
      futures.add(_fetchRouteInfo(destinationPoint, routeType));
    }

    final results = await Future.wait(futures);

    setState(() {
      _availableRoutes = results.whereType<RouteInfo>().toList();
      if (_availableRoutes.isNotEmpty) {
        // Выбираем маршрут на машине по умолчанию
        _currentRouteInfo = _availableRoutes.firstWhere(
          (r) => r.type == RouteType.driving,
          orElse: () => _availableRoutes.first,
        );
      }
    });
  }

  // Инициализация менеджера уведомлений
  Future<void> _initNotificationManager() async {
    try {
      // await NotificationManager.initialize(); // Временно отключено
      debugPrint('📱 NotificationManager инициализация пропущена');
    } catch (e) {
      debugPrint('⚠️ Ошибка инициализации уведомлений: $e');
    }
  }

  // Инициализация голосового сервиса
  Future<void> _initVoiceService() async {
    try {
      await VoiceService().initialize();
      debugPrint('✅ Голосовая озвучка инициализирована');
    } catch (e) {
      debugPrint('⚠️ Ошибка инициализации голосовой озвучки: $e');
    }
  }

  // Обновление ограничения скорости (км/ч) из внешнего источника (Яндекс API)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Отслеживаем смену языка приложения и синхронизируем TTS
    final localeCode = context.locale.toString();
    if (_lastLocaleCode != localeCode) {
      _lastLocaleCode = localeCode;
      VoiceService().syncLanguageByLocale(localeCode);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _positionStream?.cancel();
    _periodicRerouteTimer?.cancel();
    _searchDebouncer.dispose();
    NotificationManager().dispose();
    VoiceService().dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Когда пользователь уходит с главного экрана, очищаем маршрут
    if (_routePolyline != null || _isNavigating) {
      _clearRoute();
    }
    super.deactivate();
  }

  Future<void> _determinePosition() async {
    if (_isLoadingLocation) return; // Предотвращаем повторные вызовы

    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      // Проверяем, включены ли службы геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          final result =
              await LocationPermissionDialog.showLocationServiceDialog(context);
          if (result == true) {
            // Открываем настройки локации
            await Geolocator.openLocationSettings();
          }
        }
        return;
      }

      // Проверяем разрешения (без кастомных диалогов — полагаемся на системные)
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Системный промпт
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showError('error_location_denied'.tr());
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Без пользовательских диалогов, сообщаем об ошибке и выходим
        if (mounted) {
          _showError('error_location_denied_permanently'.tr());
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoadingLocation = true);
      }

      // 🚀 Стратегия: Сначала быстрое местоположение, потом точное

      // Шаг 1: Попробуем получить последнее известное местоположение (мгновенно)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        debugPrint('📍 Используем последнее известное местоположение');
        setState(() {
          _currentPosition = Point(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        });

        // Сразу показываем приблизительное местоположение
        _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition!, zoom: 14),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 0.5,
          ),
        );

        _updateMapObjects();
      }

      // Шаг 2: Получаем быстрое приблизительное местоположение (до 10 сек)
      try {
        final approximate =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⏱️ Таймаут приблизительного местоположения');
                throw TimeoutException('Approximate location timeout');
              },
            );

        if (mounted) {
          debugPrint('📍 Приблизительное местоположение получено');
          setState(() {
            _currentPosition = Point(
              latitude: approximate.latitude,
              longitude: approximate.longitude,
            );
          });

          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition!, zoom: 15),
            ),
            animation: const MapAnimation(
              type: MapAnimationType.smooth,
              duration: 0.8,
            ),
          );

          _updateMapObjects();
        }
      } catch (e) {
        debugPrint('⚠️ Не удалось получить приблизительное местоположение: $e');
        // Продолжаем работу - будем пытаться получить точное
      }

      // Шаг 3: Получаем точное местоположение с GPS (до 45 сек)
      try {
        final precise =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              const Duration(seconds: 45),
              onTimeout: () {
                debugPrint(
                  '⏱️ Таймаут точного местоположения - используем приблизительное',
                );
                throw TimeoutException('Precise location timeout');
              },
            );

        if (mounted) {
          debugPrint(
            '📍 Точное местоположение получено (точность: ${precise.accuracy}м)',
          );
          setState(() {
            _currentPosition = Point(
              latitude: precise.latitude,
              longitude: precise.longitude,
            );
          });

          // Плавно уточняем позицию
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition!, zoom: 15),
            ),
            animation: const MapAnimation(
              type: MapAnimationType.smooth,
              duration: 1.0,
            ),
          );

          _updateMapObjects();
        }
      } catch (e) {
        debugPrint('⚠️ Не удалось получить точное местоположение: $e');
        // Если точное местоположение не получено, продолжаем с приблизительным
        // GPS stream продолжит обновлять позицию в фоне
      }
    } on TimeoutException {
      if (mounted) {
        _showError(
          'Время определения местоположения истекло. Попробуйте снова',
        );
        // Не подставляем фейковую позицию
        _currentPosition = null;
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка определения местоположения: $e');
        // Не подставляем фейковую позицию
        _currentPosition = null;
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _loadNearbyServices() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Загружаем все демо-сервисы
      final services = DemoServicesData.getDemoServices();

      if (mounted) {
        setState(() {
          _allServices = services;
          _filteredServices = List.from(_allServices);
        });
        // Обновляем карту после загрузки данных
        _updateMapObjects();
      }
    } catch (e) {
      if (mounted) _showError('error_loading_services'.tr());
    }
  }

  void _loadGasStations() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Загружаем все демо-заправки
      final gasStations = DemoGasStationsData.getDemoGasStations();

      if (mounted) {
        setState(() {
          _allGasStations = gasStations;
          _filteredGasStations = List.from(_allGasStations);
        });
        // Обновляем карту после загрузки данных
        _updateMapObjects();
      }
    } catch (e) {
      if (mounted) _showError('error_loading_services'.tr());
    }
  }

  void _setMapTheme(bool isDarkMode) {
    if (_mapController != null) {
      try {
        // Пытаемся установить тему карты
        // В Yandex Mapkit 4.2.1 может быть другой API для темы
        // TODO: Реализовать когда API будет доступно
      } catch (e) {
        // Игнорируем ошибки установки темы
      }
    }
  }

  void _updateMapObjects() async {
    // Защита от повторных вызовов
    if (_isUpdatingMapObjects) {
      return;
    }

    _isUpdatingMapObjects = true;

    _mapObjects.clear();

    // Пытаемся загрузить иконки из ассетов (один раз, с кэшем)
    await _ensureMarkerAssetsLoaded();

    // Добавляем маршрут, если он построен
    if (_routePolyline != null) {
      _mapObjects.add(_routePolyline!);
    }

    // ✨ ИСПОЛЬЗУЕМ ТОЛЬКО ВСТРОЕННЫЙ ИНДИКАТОР ЯНДЕКСА
    // Никаких кастомных стрелок - только то что предоставляет Яндекс MapKit
    debugPrint('📍 Используем ТОЛЬКО встроенный индикатор от Яндекса');

    // Правильная логика переключения: показываем ТОЛЬКО выбранный тип
    // Используем пакетное добавление маркеров для оптимизации
    if (_showGasStations == true) {
      // Показываем ТОЛЬКО заправки
      for (var gasStation in _filteredGasStations) {
        // Проверяем кэш перед созданием нового маркера
        final cacheKey = 'gas_${gasStation.id}';
        if (_cachedMarkers.containsKey(cacheKey)) {
          _mapObjects.add(_cachedMarkers[cacheKey]!);
        } else {
          await _addMarkerSync(
            gasStation.id,
            gasStation.latitude,
            gasStation.longitude,
            Colors.green,
            '⛽',
            onTap: () => _showGasStationDetails(gasStation),
            cacheKey: cacheKey,
          );
        }
      }
    } else {
      // Показываем ТОЛЬКО автосервисы
      for (var service in _filteredServices) {
        // Проверяем кэш перед созданием нового маркера
        final cacheKey = 'service_${service.id}';
        if (_cachedMarkers.containsKey(cacheKey)) {
          _mapObjects.add(_cachedMarkers[cacheKey]!);
        } else {
          await _addMarkerSync(
            service.id,
            service.latitude,
            service.longitude,
            Colors.red,
            '🔧',
            onTap: () => _showServiceDetails(service),
            cacheKey: cacheKey,
          );
        }
      }
    }

    // Обновляем карту с новыми объектами
    if (_mapController != null && mounted) {
      setState(() {});
    }

    _isUpdatingMapObjects = false;
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      if (_showGasStations == true) {
        // Применяем фильтры к заправкам
        _filteredGasStations = _allGasStations.where((gasStation) {
          bool matchesRating =
              _selectedRating == 0.0 || gasStation.rating >= _selectedRating;

          // Применяем поисковый фильтр, если есть поисковый запрос
          bool matchesSearch =
              _searchQuery.isEmpty ||
              gasStation.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              gasStation.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              gasStation.fuelTypes.any(
                (fuel) =>
                    fuel.toLowerCase().contains(_searchQuery.toLowerCase()),
              ) ||
              (gasStation.address?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);

          return matchesRating && matchesSearch;
        }).toList();
      } else {
        // Применяем фильтры к автосервисам (по умолчанию)
        _filteredServices = _allServices.where((service) {
          bool matchesRating =
              _selectedRating == 0.0 || service.rating >= _selectedRating;
          bool matchesCategory =
              _selectedCategory == null ||
              service.services.contains(_selectedCategory);

          // Применяем поисковый фильтр, если есть поисковый запрос
          bool matchesSearch =
              _searchQuery.isEmpty ||
              service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              service.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              service.services.any(
                (serviceItem) => serviceItem.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              ) ||
              (service.address?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);

          return matchesRating && matchesCategory && matchesSearch;
        }).toList();
      }
    });
    _updateMapObjects();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'filters'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('rating'.tr()),
                Slider(
                  value: _selectedRating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 5,
                  label: _selectedRating.toString(),
                  onChanged: (value) {
                    setModalState(() => _selectedRating = value);
                  },
                ),
                const SizedBox(height: 16),
                Text('service_type'.tr()),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  hint: Text('select_category'.tr()),
                  items:
                      <String>[
                            'Remont',
                            'Texnik ko\'rik',
                            'Dvigatel',
                            'Moyka',
                            'Shina',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.tr()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedRating = 0.0;
                            _selectedCategory = null;
                            _searchQuery = ''; // Сбрасываем поисковый запрос
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Text('clear'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Text('apply'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showServiceDetails(AutoServiceModel service) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение сервиса
            if (service.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.business, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              service.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(service.address ?? ''),
            const SizedBox(height: 8),
            Text('${'rating'.tr()}: ${service.rating}'),
            const SizedBox(height: 8),
            Text('${'working_hours'.tr()}: ${service.workingHours}'),
            const SizedBox(height: 8),
            Text('${'phone'.tr()}: ${service.phone}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _buildRoute(service.latitude, service.longitude);
                    },
                    icon: const Icon(Icons.directions),
                    label: Text('build_route'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _buildRoute(service.latitude, service.longitude);
                    },
                    icon: const Icon(Icons.map),
                    label: Text('open_map'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGasStationDetails(GasStationModel gasStation) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение заправки
            if (gasStation.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gasStation.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_gas_station, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              gasStation.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(gasStation.address ?? ''),
            const SizedBox(height: 8),
            Text('${'rating'.tr()}: ${gasStation.rating}'),
            const SizedBox(height: 8),
            Text('${'working_hours'.tr()}: ${gasStation.workingHours}'),
            const SizedBox(height: 8),
            Text('${'phone'.tr()}: ${gasStation.phone}'),
            const SizedBox(height: 8),
            Text(
              '${'price_per_liter'.tr()}: ${gasStation.pricePerLiter?.toStringAsFixed(0) ?? 'N/A'} ${gasStation.currency ?? ''}',
            ),
            const SizedBox(height: 8),
            Text('${'fuel_types'.tr()}: ${gasStation.fuelTypes.join(', ')}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _buildRoute(gasStation.latitude, gasStation.longitude);
                    },
                    icon: const Icon(Icons.directions),
                    label: Text('build_route'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _buildRoute(gasStation.latitude, gasStation.longitude);
                    },
                    icon: const Icon(Icons.map),
                    label: Text('open_map'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buildRoute(double latitude, double longitude) async {
    debugPrint('🔹 _buildRoute начат: lat=$latitude, lng=$longitude');
    try {
      if (_currentPosition == null) {
        debugPrint('❌ Текущее местоположение не определено');
        return;
      }

      debugPrint(
        '✅ Текущее местоположение: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      final destinationPoint = Point(latitude: latitude, longitude: longitude);
      _destinationPoint = destinationPoint;

      // Показываем индикатор загрузки
      if (mounted) {
        setState(() => _isLoadingLocation = true);
      }

      // Попробуем сразу Яндекс API для ускорения
      final yandexOk = await _tryBuildRouteViaYandex(destinationPoint);
      if (yandexOk) {
        _startPeriodicLiveReroute();
        return; // Не пробуем YandexDriving, всё уже готово
      }
      try {
        // Делаем до двух попыток построения маршрута по дорогам
        Exception? lastError;
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            final resultWithSession = await YandexDriving.requestRoutes(
              points: [
                RequestPoint(
                  point: _currentPosition!,
                  requestPointType: RequestPointType.wayPoint,
                ),
                RequestPoint(
                  point: destinationPoint,
                  requestPointType: RequestPointType.wayPoint,
                ),
              ],
              drivingOptions: const DrivingOptions(
                initialAzimuth: null,
                routesCount: 3,
              ),
            );

            final session = resultWithSession.$1;
            final resultFuture = resultWithSession.$2;
            final result = await resultFuture;
            session.close();

            if (result.routes == null || result.routes!.isEmpty) {
              // Печатаем возможную причину
              try {
                // ignore: avoid_dynamic_calls
              } catch (_) {}
              throw Exception('Маршрут не найден');
            }

            final route = result.routes!.first;

            // Сохраняем оригинальные точки маршрута
            _originalRoutePoints = List.from(route.geometry.points);
            _remainingRoutePoints = List.from(route.geometry.points);

            _routePolyline = PolylineMapObject(
              mapId: const MapObjectId('route'),
              polyline: Polyline(points: route.geometry.points),
              strokeColor: Colors.blue,
              strokeWidth: 6.0,
            );

            _updateMapObjects();
            _startPeriodicLiveReroute();

            // Успешно — выходим из цикла
            lastError = null;
            break;
          } catch (e) {
            lastError = e is Exception ? e : Exception(e.toString());
            // Небольшая пауза между попытками
            final delayMs = 300 * attempt; // экспоненциальная пауза
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }

        if (lastError != null) {
          // Пробуем Яндекс API как внутренний фолбэк
          final ok = await _tryBuildRouteViaYandex(destinationPoint);
          if (!ok && mounted) {
            // Не удалось построить маршрут
          }
        }
      } catch (e) {
        // Пробуем Яндекс API как фолбэк внутри приложения
        final ok = await _tryBuildRouteViaYandex(destinationPoint);
        if (!ok && mounted) {
          // Не удалось построить маршрут
        }
      }
    } catch (e) {
      // Игнорируем ошибки построения маршрута
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // === НАЧАЛО GPS НАВИГАЦИИ ===

  Future<void> _startNavigation() async {
    debugPrint('🚀 Старт навигации, _currentPosition: $_currentPosition');
    if (_routePolyline == null || _originalRoutePoints.isEmpty) {
      _showError('Сначала постройте маршрут');
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    // Оставляем встроенный индикатор Яндекса включенным всегда

    setState(() {
      _isNavigating = true;
      _didFitRouteOnce = true; // больше не делаем fit bounds
      // Сбрасываем оставшийся маршрут
      _remainingRoutePoints = List.from(_originalRoutePoints);

      // Инициализируем оставшееся расстояние и время
      _remainingDistance = _currentRouteInfo?.distance ?? 0.0;
      _remainingTime = _currentRouteInfo?.duration ?? 0.0;

      // Фиксированная стрелка убрана - используем только стрелку на карте
    });

    // Голосовое уведомление о начале навигации
    if (_voiceEnabled) {
      VoiceService().speak(NavigationPhrases.navigationStarted);
    }

    // Принудительно обновляем маркер сразу после старта
    _updateMapObjects();
    debugPrint('📍 Маркер обновлён после старта навигации');

    // 🎥 Плавно перемещаем камеру к текущей позиции с наклоном
    if (_currentPosition != null && _mapController != null) {
      try {
        await _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 18,
              azimuth: _lastHeading ?? 0,
              tilt: 30, // Наклон для 3D эффекта
            ),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 1.5, // Плавное начало навигации
          ),
        );
      } catch (e) {
        // Игнорируем ошибки
      }
    }

    // Поток GPS обновлений с оптимальными настройками
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter:
                5, // Обновляем каждые 5 метров для плавной навигации
            // Убираем timeLimit для стабильной работы на реальных устройствах
          ),
        ).listen(
          (Position pos) async {
            // Обновляем скорость ВСЕГДА (не только во время навигации)
            if (mounted) {
              setState(() {
                _speedKmh = pos.speed * 3.6;
                _movementType = _speedKmh < _walkThresholdKmh
                    ? 'walking'.tr()
                    : 'driving'.tr();
              });
            }

            // Проверяем превышение скорости, если лимит известен
            if (_speedLimitKmh != null && _speedKmh.isFinite) {
              final limit = _speedLimitKmh!;
              // Допускаем небольшой порог в 3 км/ч
              final isOver = _speedKmh > (limit + 3);
              final now = DateTime.now();
              final canSpeak =
                  _voiceEnabled &&
                  (_lastOverspeedHintAt == null ||
                      now.difference(_lastOverspeedHintAt!).inSeconds > 25);

              if (isOver && canSpeak) {
                _lastOverspeedHintAt = now;
                VoiceService().speak(
                  NavigationPhrases.getOverspeedPhrase(limit),
                );
              }
            }

            final userPoint = Point(
              latitude: pos.latitude,
              longitude: pos.longitude,
            );

            // Обновляем текущую позицию для маркера и камеры
            _currentPosition = userPoint;

            // Обновляем направление движения: используем GPS heading, иначе — азимут к следующей точке маршрута
            double computedHeading;
            if (pos.heading >= 0) {
              computedHeading = pos.heading;
            } else {
              computedHeading =
                  _bearingToNextPoint(userPoint) ?? (_lastHeading ?? 0);
            }

            // Сглаживание поворота
            if (_currentHeading == null) {
              _currentHeading = computedHeading;
            } else {
              _currentHeading =
                  _currentHeading! * 0.85 + computedHeading * 0.15;
            }
            _lastHeading = _currentHeading;

            // Обновляем фиксированную стрелку на экране
            // Фиксированная стрелка убрана

            // Убираем пройденные точки маршрута
            _updateRemainingRoute(userPoint);

            // Принудительно обновляем маркер на карте
            _updateMapObjects();

            // 🎥 Камера следует за пользователем — только при заметном изменении,
            // чтобы карта не "жила своей жизнью"
            final nowCam = DateTime.now();
            final minIntervalOk =
                _lastCameraFollowAt == null ||
                nowCam.difference(_lastCameraFollowAt!).inMilliseconds > 900;
            final lastPt = _lastCameraPoint;
            final movedMeters = (lastPt == null)
                ? double.infinity
                : Geolocator.distanceBetween(
                    lastPt.latitude,
                    lastPt.longitude,
                    userPoint.latitude,
                    userPoint.longitude,
                  );
            final lastAz = _lastCameraAzimuth ?? (_lastHeading ?? 0);
            final az = _lastHeading ?? 0.0;
            double deltaAz = (az - lastAz).abs();
            if (deltaAz > 180) deltaAz = 360 - deltaAz;
            final headingChanged = deltaAz > 8.0;
            final movedEnough = movedMeters > 8.0;
            final speedEnough = _speedKmh > 0.8; // не дёргать камеру на месте
            if (minIntervalOk &&
                (movedEnough || headingChanged) &&
                speedEnough) {
              _followUserWithCamera(userPoint, az);
              _lastCameraPoint = userPoint;
              _lastCameraAzimuth = az;
              _lastCameraFollowAt = nowCam;
            }

            // Обновляем дистанцию до следующего маневра и авто-продвижение
            _updateNextManeuverProgress(userPoint);

            // Проверяем необходимость живого перерасчета (если сильно ушли от маршрута)
            _rerouteIfOffPath(userPoint);

            // Проверяем прибытие
            if (_remainingRoutePoints.isNotEmpty) {
              final lastPoint = _remainingRoutePoints.last;
              final distance = Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                lastPoint.latitude,
                lastPoint.longitude,
              );
              if (distance < 30 && mounted) {
                // Голосовое уведомление о прибытии
                if (_voiceEnabled) {
                  VoiceService().speak(NavigationPhrases.destinationReached);
                }
                _stopNavigation();
                _clearRoute();
              }
            }

            _updateMapObjects();
          },
          onError: (error) {
            debugPrint('⚠️ Ошибка GPS в навигации (не критично): $error');
            // Продолжаем навигацию даже при ошибках GPS
          },
        );
  }

  // Убираем пройденные точки маршрута (улучшенная логика)
  void _updateRemainingRoute(Point userPoint) {
    if (_remainingRoutePoints.isEmpty) return;

    // Оптимизация: обновляем UI навигации не чаще раза в секунду
    final now = DateTime.now();

    // Debounce: если прошло меньше секунды с последнего обновления,
    // пересчитаем навигационные данные, но не будем вызывать setState
    // (чтобы не перегружать UI). Защищаемся от null корректно.
    if (_lastNavigationUpdate != null &&
        now.difference(_lastNavigationUpdate!).inMilliseconds < 1000) {
      _calculateNavigationData(userPoint);
      return;
    }

    // Иначе пересчитываем и обновляем UI
    _calculateNavigationData(userPoint);
    if (mounted) {
      _lastNavigationUpdate = now;
      setState(() {});
    }
  }

  // Вычисление данных навигации без setState (улучшенная логика)
  void _calculateNavigationData(Point userPoint) {
    if (_remainingRoutePoints.isEmpty) return;

    // Находим ближайшую точку на маршруте
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _remainingRoutePoints.length; i++) {
      final point = _remainingRoutePoints[i];
      final distance = Geolocator.distanceBetween(
        userPoint.latitude,
        userPoint.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // УЛУЧШЕННАЯ ЛОГИКА: Удаляем пройденные точки более агрессивно
    // Если пользователь близко к точке маршрута (в пределах 20 метров)
    // убираем все точки до этой включительно
    if (minDistance < 20 && closestIndex > 0) {
      debugPrint('🗺️ Удаляем $closestIndex пройденных точек маршрута');
      _remainingRoutePoints = _remainingRoutePoints.sublist(closestIndex);

      // Обновляем полилинию маршрута (серый цвет для пройденного)
      if (_remainingRoutePoints.length >= 2) {
        final currentRouteColor = _currentRouteInfo?.color ?? Colors.blue;
        _routePolyline = PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: Polyline(points: _remainingRoutePoints),
          strokeColor: currentRouteColor,
          strokeWidth: 6.0,
        );

        _updateMapObjects();
      } else if (_remainingRoutePoints.length == 1) {
        // Если осталась одна точка - мы почти на месте
        debugPrint('🎯 Осталась последняя точка маршрута!');
      }
    }

    // 📏 Рассчитываем оставшееся расстояние
    _remainingDistance = 0.0;
    if (_remainingRoutePoints.isNotEmpty) {
      // Расстояние от текущей позиции до первой точки маршрута
      _remainingDistance = Geolocator.distanceBetween(
        userPoint.latitude,
        userPoint.longitude,
        _remainingRoutePoints.first.latitude,
        _remainingRoutePoints.first.longitude,
      );

      // Плюс расстояние между всеми точками маршрута
      for (int i = 0; i < _remainingRoutePoints.length - 1; i++) {
        _remainingDistance += Geolocator.distanceBetween(
          _remainingRoutePoints[i].latitude,
          _remainingRoutePoints[i].longitude,
          _remainingRoutePoints[i + 1].latitude,
          _remainingRoutePoints[i + 1].longitude,
        );
      }
    }

    // ⏱️ Рассчитываем оставшееся время с учетом текущей скорости
    if (_speedKmh > _walkThresholdKmh) {
      // Используем реальную скорость если движемся
      _remainingTime = (_remainingDistance / 1000) / _speedKmh * 3600;
    } else {
      // Если стоим или медленно движемся, используем примерную скорость
      final estimatedSpeed = _currentRouteInfo?.type == RouteType.walking
          ? 5.0 // 5 км/ч для пешехода
          : 30.0; // 30 км/ч для машины в городе
      _remainingTime = (_remainingDistance / 1000) / estimatedSpeed * 3600;
    }

    debugPrint(
      '📊 Навигация: Осталось ${(_remainingDistance / 1000).toStringAsFixed(2)} км, ${(_remainingTime / 60).toStringAsFixed(1)} мин, точек: ${_remainingRoutePoints.length}',
    );
  }

  // Создаем иконку стрелки навигации (стиль geo_way.png)

  // Камера следует за пользователем с видом "сзади" (как в Яндекс Картах)
  void _followUserWithCamera(Point userPoint, double heading) {
    if (_mapController == null) return;

    try {
      // 🎥 Плавное следование камеры с эффектом "езды"
      _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userPoint,
            zoom: 18, // Приближенный зум для навигации
            azimuth: heading, // Поворот карты по направлению движения
            tilt: 30, // Наклон для 3D эффекта (как в Яндекс Картах)
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0, // Более плавное движение
        ),
      );
    } catch (e) {
      // Игнорируем ошибки движения камеры
    }
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    _periodicRerouteTimer?.cancel();

    // Встроенный индикатор Яндекса всегда включен

    // Голосовое уведомление об остановке навигации
    if (_voiceEnabled) {
      VoiceService().speak(NavigationPhrases.navigationStopped);
    }

    setState(() {
      _isNavigating = false;
      _speedKmh = 0.0;
      _movementType = '';
      _remainingDistance = 0.0;
      _remainingTime = 0.0;
      _lastHeading = null;
      _currentHeading = null; // Сбрасываем текущее направление
      // Фиксированная стрелка убрана
      // Восстанавливаем оригинальный маршрут
      if (_originalRoutePoints.isNotEmpty) {
        _routePolyline = PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: Polyline(points: _originalRoutePoints),
          strokeColor: Colors.blue,
          strokeWidth: 6.0,
        );
      }
    });

    // 🎥 Плавно возвращаем камеру в обычное положение (без наклона)
    if (_currentPosition != null && _mapController != null) {
      try {
        _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15,
              azimuth: 0, // Возвращаем север наверх
              tilt: 0, // Убираем наклон
            ),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 1.0,
          ),
        );
      } catch (e) {
        // Игнорируем ошибки
      }
    }

    _updateMapObjects();
  }

  // === КОНЕЦ GPS НАВИГАЦИИ ===

  // Синхронное добавление маркера без setState
  Future<void> _addMarkerSync(
    String id,
    double latitude,
    double longitude,
    Color color,
    String emoji, {
    VoidCallback? onTap,
    String? cacheKey,
  }) async {
    try {
      // Если есть подходящая иконка ассета – используем её, иначе рисуем
      BitmapDescriptor? assetIcon;
      if (emoji == '⛽') {
        assetIcon = _gasAssetIcon;
      } else if (emoji == '🔧') {
        assetIcon = _serviceAssetIcon;
      }

      assetIcon ??= await _createSimpleMarker(color, emoji);

      final marker = PlacemarkMapObject(
        mapId: MapObjectId('${id}_marker'),
        point: Point(latitude: latitude, longitude: longitude),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: assetIcon,
            scale: _computeScale(base: 0.20),
          ),
        ),
        opacity: 1.0,
        consumeTapEvents: onTap != null,
        onTap: onTap != null
            ? (PlacemarkMapObject self, Point point) => onTap()
            : null,
      );

      _mapObjects.add(marker);

      // Сохраняем в кэш если указан ключ
      if (cacheKey != null) {
        _cachedMarkers[cacheKey] = marker;
      }
    } catch (e) {
      // Игнорируем ошибки добавления маркера
    }
  }

  // Загружаем иконки маркеров из ассетов один раз и кэшируем
  Future<void> _ensureMarkerAssetsLoaded() async {
    try {
      // Сервис: пробуем новые имена, затем старые
      _serviceAssetIcon ??= await _tryLoadFirstAvailable([
        'assets/icons/auto_service.png',
        'assets/icons/service_marker.png',
      ]);

      // Заправка: пробуем новые имена, затем старые
      _gasAssetIcon ??= await _tryLoadFirstAvailable([
        'assets/icons/gas_station.png',
        'assets/icons/gas_station_marker.png',
      ]);

      // Убрали загрузку иконок текущей позиции - используем встроенный индикатор Яндекс MapKit
      debugPrint(
        '✅ Используем встроенный индикатор пользователя от Яндекс MapKit',
      );
    } catch (e) {
      // Игнорируем ошибки загрузки ассетов маркеров
    }
  }

  Future<BitmapDescriptor?> _tryLoadFirstAvailable(
    List<String> candidates,
  ) async {
    for (final raw in candidates) {
      // Пробуем как есть
      final direct = await _tryLoadBitmapFromAsset(raw);
      if (direct != null) {
        return direct;
      }
      // Если нет расширения .png – пробуем добавить
      if (!raw.toLowerCase().endsWith('.png')) {
        final withPng = '$raw.png';
        final pngTry = await _tryLoadBitmapFromAsset(withPng);
        if (pngTry != null) {
          debugPrint('Loaded marker asset: $withPng');
          return pngTry;
        }
      }
    }
    debugPrint(
      'No marker assets found in candidates: ${candidates.join(', ')}',
    );
    return null;
  }

  // Динамический масштаб в зависимости от текущего зума
  double _computeScale({required double base}) {
    // Делаем рост размера умеренным и ограниченным
    final double minZoom = 4.0;
    final double maxZoom = 20.0;
    final double z = _currentZoom.clamp(minZoom, maxZoom);
    // Коэффициент 0.6..1.0
    final double k = 0.6 + ((z - minZoom) / (maxZoom - minZoom)) * 0.4;
    return (base * k).clamp(base * 0.6, base * 1.0);
  }

  // Азимут до следующей точки маршрута (в градусах 0..360) для поворота стрелки
  double? _bearingToNextPoint(Point from) {
    Point? target;
    if (_remainingRoutePoints.isNotEmpty) {
      target = _remainingRoutePoints.first;
      // Если слишком близко к первой, взять следующую для стабильности
      if (_remainingRoutePoints.length >= 2) {
        final d = Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          target.latitude,
          target.longitude,
        );
        if (d < 8) {
          target = _remainingRoutePoints[1];
        }
      }
    } else if (_originalRoutePoints.isNotEmpty) {
      // Найти ближайшую точку и выбрать следующую
      int idx = 0;
      double minD = double.infinity;
      for (int i = 0; i < _originalRoutePoints.length; i++) {
        final p = _originalRoutePoints[i];
        final d = Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          p.latitude,
          p.longitude,
        );
        if (d < minD) {
          minD = d;
          idx = i;
        }
      }
      if (idx < _originalRoutePoints.length - 1) {
        target = _originalRoutePoints[idx + 1];
      }
    }

    if (target == null) return null;

    final lat1 = from.latitude * math.pi / 180.0;
    final lon1 = from.longitude * math.pi / 180.0;
    final lat2 = target.latitude * math.pi / 180.0;
    final lon2 = target.longitude * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double brng = math.atan2(y, x) * 180.0 / math.pi; // -180..+180
    if (brng < 0) brng += 360.0;
    return brng;
  }

  // Удалено: больше не используем bitmap стрелку

  Future<BitmapDescriptor?> _tryLoadBitmapFromAsset(String assetPath) async {
    try {
      debugPrint('🔎 Попытка загрузить ассет маркера: $assetPath');
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) {
        debugPrint('⚠️ Загружен пустой файл: $assetPath');
        return null;
      }
      final desc = BitmapDescriptor.fromBytes(bytes);
      debugPrint('✅ Успешно создан BitmapDescriptor для $assetPath');
      return desc;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ассета $assetPath: $e');
      return null; // файла может не быть – это не ошибка
    }
  }

  // Кастомная навигационная стрелка убрана - используем только Яндекс

  // Пиновая гео-метка (капля) с обводкой и эмодзи/символом внутри
  Future<BitmapDescriptor> _createSimpleMarker(
    Color color,
    String emoji,
  ) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(120, 150);

      // Тень
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(size.width / 2, size.height - 30),
        20,
        shadowPaint,
      );

      // Основная капля
      final path = Path();
      final center = Offset(size.width / 2, size.height / 2);
      path.addOval(Rect.fromCircle(center: center, radius: 30));
      path.moveTo(size.width / 2, size.height / 2 + 30);
      path.lineTo(size.width / 2 - 10, size.height - 30);
      path.lineTo(size.width / 2 + 10, size.height - 30);
      path.close();

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(path, strokePaint);

      // Эмодзи/символ внутри
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
      textPainter.text = TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 32, color: Colors.white),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2 - 5,
        ),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error creating simple marker: $e');
      // Возвращаем минимальную иконку в случае ошибки
      return await _createMinimalMarker();
    }
  }

  // Создаем минимальную иконку как fallback
  Future<BitmapDescriptor> _createMinimalMarker() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(20, 20);

      // Рисуем простой красный круг
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 8, paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to create minimal marker');
      }

      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error creating minimal marker: $e');
      // В крайнем случае возвращаем пустую иконку
      final recorder = ui.PictureRecorder();
      final size = const Size(1, 1);
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    }
  }

  /// Плавно перемещает камеру чтобы показать весь маршрут
  Future<void> _moveCameraToShowFullRoute(List<Point> points) async {
    if (points.isEmpty || _mapController == null) return;

    // Находим границы маршрута (min/max широты и долготы)
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    // Вычисляем центр и добавляем padding (10% с каждой стороны)
    final latPadding = (maxLat - minLat) * 0.15; // 15% отступ
    final lonPadding = (maxLon - minLon) * 0.15;

    minLat -= latPadding;
    maxLat += latPadding;
    minLon -= lonPadding;
    maxLon += lonPadding;

    // Вычисляем центральную точку
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    // Вычисляем подходящий уровень зума
    // Чем больше маршрут, тем меньше зум
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    double zoom;
    if (maxDiff > 0.5) {
      zoom = 10.0; // Очень большой маршрут
    } else if (maxDiff > 0.1) {
      zoom = 12.0; // Большой маршрут
    } else if (maxDiff > 0.05) {
      zoom = 13.0; // Средний маршрут
    } else if (maxDiff > 0.02) {
      zoom = 14.0; // Небольшой маршрут
    } else {
      zoom = 15.0; // Маленький маршрут
    }

    debugPrint(
      '📹 Перемещаем камеру: центр ($centerLat, $centerLon), зум $zoom',
    );

    // Плавно перемещаем камеру
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: centerLat, longitude: centerLon),
          zoom: zoom,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 1.5, // 1.5 секунды - как в Яндекс Картах
      ),
    );
  }

  void _clearRoute() {
    // Если навигация активна, сначала останавливаем её
    if (_isNavigating) {
      _stopNavigation();
    }

    setState(() {
      _routePolyline = null;
      _originalRoutePoints = [];
      _remainingRoutePoints = [];
      _destinationPoint = null;
    });
    _updateMapObjects();
  }

  // === ЖИВОЙ МАРШРУТ: периодический перерасчет ===
  void _startPeriodicLiveReroute() {
    // Запускаем таймер периодического обновления маршрута, если есть цель
    _periodicRerouteTimer?.cancel();
    if (_destinationPoint == null) return;

    // Разная частота для режимов: пешком реже, авто чаще, транспорт средне
    final routeType = _currentRouteInfo?.type ?? RouteType.driving;
    final Duration interval;
    switch (routeType) {
      case RouteType.walking:
        interval = const Duration(minutes: 3);
        break;
      case RouteType.transit:
        interval = const Duration(minutes: 2);
        break;
      case RouteType.driving:
        interval = const Duration(seconds: 60);
        break;
    }

    _periodicRerouteTimer = Timer.periodic(interval, (_) async {
      if (!mounted || _destinationPoint == null || _currentPosition == null) {
        return;
      }
      // Не спамим перерасчетами во время активного офф-роута
      final now = DateTime.now();
      if (_lastRerouteAt != null &&
          now.difference(_lastRerouteAt!).inSeconds < 20) {
        return;
      }
      // Строим актуальный маршрут от текущей позиции до цели для выбранного типа
      try {
        final info = await _fetchRouteInfo(_destinationPoint!, routeType);
        if (info != null) {
          await _applySelectedRoute(_destinationPoint!, info);
          _lastRerouteAt = now;
        }
      } catch (_) {}
    });
  }

  // Живой перерасчет при сходе с маршрута
  Future<void> _rerouteIfOffPath(Point userPoint) async {
    if (_destinationPoint == null || _currentRouteInfo == null) return;
    // Если маршрута нет или слишком мало точек, нет смысла
    if (_remainingRoutePoints.length < 2) return;

    // Находим ближайшую точку маршрута
    double minDistance = double.infinity;
    for (final p in _remainingRoutePoints) {
      final d = Geolocator.distanceBetween(
        userPoint.latitude,
        userPoint.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < minDistance) minDistance = d;
    }

    // Если ушли дальше порога — перестроить маршрут
    const double offRouteThresholdMeters = 35.0;
    if (minDistance > offRouteThresholdMeters) {
      final now = DateTime.now();
      // Дебаунс перестроения, чтобы не дергать слишком часто
      if (_lastRerouteAt != null &&
          now.difference(_lastRerouteAt!).inSeconds < 15) {
        return;
      }
      _lastRerouteAt = now;
      try {
        final info = await _fetchRouteInfo(
          _destinationPoint!,
          _currentRouteInfo!.type,
        );
        if (info != null) {
          await _applySelectedRoute(_destinationPoint!, info);
        }
      } catch (_) {}
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Публичный метод для построения маршрута извне
  void buildRouteTo(double latitude, double longitude) {
    debugPrint('🔹 buildRouteTo вызван: lat=$latitude, lng=$longitude');
    _buildRoute(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return LoadingOverlay(
      isLoading: _isLoadingLocation,
      message: 'loading_map'.tr(),
      child: Stack(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return YandexMap(
                onMapCreated: (controller) async {
                  _mapController = controller;

                  // Включаем встроенный индикатор пользователя от Яндекс MapKit
                  await _mapController?.toggleUserLayer(visible: true);

                  if (_currentPosition != null) {
                    _mapController?.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _currentPosition!, zoom: 15),
                      ),
                    );
                  }
                  _setMapTheme(themeProvider.isDarkMode);
                },
                mapObjects: _mapObjects,
                onCameraPositionChanged:
                    (
                      CameraPosition position,
                      CameraUpdateReason reason,
                      bool finished,
                    ) {
                      // Обновляем зум и пересобираем объекты только при значимом изменении
                      final newZoom = position.zoom;
                      if ((newZoom - _currentZoom).abs() >= 0.3 ||
                          (finished && !_isNavigating)) {
                        _currentZoom = newZoom;
                        if (!_isNavigating) {
                          _updateMapObjects();
                        }
                      } else {
                        _currentZoom = newZoom;
                      }
                    },
              );
            },
          ),

          // === БЛОК УПРАВЛЕНИЯ МАРШРУТОМ (внизу экрана) ===
          if (_routePolyline != null && !_isNavigating)
            Positioned(
              bottom: 0, // Прилепляем к низу экрана
              left: 0,
              right: 0,
              child: _availableRoutes.isNotEmpty
                  ? RouteTypeSelector(
                      routes: _availableRoutes,
                      selectedRoute: _currentRouteInfo,
                      onRouteSelected: (route) async {
                        // Применяем выбранный маршрут
                        if (_routePolyline != null) {
                          final destination = Point(
                            latitude:
                                _routePolyline!.polyline.points.last.latitude,
                            longitude:
                                _routePolyline!.polyline.points.last.longitude,
                          );
                          await _applySelectedRoute(destination, route);
                        }
                      },
                      onGoPressed: _startNavigation,
                      onClosePressed: _clearRoute,
                    )
                  : Container(),
            ),

          // === ПАНЕЛЬ НАВИГАЦИИ (во время движения) ===
          if (_isNavigating)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Подсказка следующего маневра + переключатель голоса
                    if (_maneuvers.isNotEmpty &&
                        _nextManeuverIndex < _maneuvers.length)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ManeuverIcon(
                              type: _maneuvers[_nextManeuverIndex].type,
                              modifier: _maneuvers[_nextManeuverIndex].modifier,
                              size: 26,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatManeuverText(
                                      _maneuvers[_nextManeuverIndex],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_distanceToNextManeuver != null)
                                    Text(
                                      _distanceToNextManeuver! < 1000
                                          ? '${_distanceToNextManeuver!.toInt()} м'
                                          : '${(_distanceToNextManeuver! / 1000).toStringAsFixed(1)} км',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _voiceEnabled = !_voiceEnabled;
                                  // Обновляем настройки VoiceService
                                  VoiceService().setEnabled(_voiceEnabled);

                                  // Голосовое подтверждение изменения настройки
                                  if (_voiceEnabled) {
                                    VoiceService().speak(
                                      'Голосовые подсказки включены',
                                    );
                                  }
                                });
                              },
                              icon: Icon(
                                _voiceEnabled
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                                color: Colors.white,
                              ),
                              tooltip: _voiceEnabled
                                  ? 'voice_on'.tr()
                                  : 'voice_off'.tr(),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Скорость
                        Column(
                          children: [
                            Icon(
                              Icons.speed,
                              color: Colors.blue[300],
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_speedKmh.toStringAsFixed(0)} ${'km_h'.tr()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _movementType,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Разделитель
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        // Оставшееся расстояние и время
                        Column(
                          children: [
                            Icon(
                              Icons.route,
                              color: Colors.green[300],
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _remainingDistance < 1000
                                  ? '${_remainingDistance.toInt()} м'
                                  : '${(_remainingDistance / 1000).toStringAsFixed(1)} км',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _remainingTime < 60
                                  ? '${_remainingTime.toInt()} сек'
                                  : '${(_remainingTime / 60).toInt()} мин',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Кнопка остановить
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _stopNavigation,
                        icon: const Icon(Icons.stop_circle, size: 24),
                        label: Text(
                          'stop_navigation'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: CustomSearchBar(
              searchText: _searchQuery,
              resultsCount: _searchQuery.isNotEmpty
                  ? _showGasStations == true
                        ? '${_filteredGasStations.length}'
                        : '${_filteredServices.length}'
                  : null,
              hintText: _showGasStations == true
                  ? 'search_gas_stations'.tr()
                  : 'search_services'.tr(),
              onChanged: (value) {
                if (!mounted) return;
                _searchQuery = value;
                setState(() {
                  if (_showGasStations == true) {
                    if (value.isEmpty) {
                      _filteredGasStations = List.from(_allGasStations);
                    } else {
                      _filteredGasStations = _allGasStations
                          .where(
                            (gasStation) =>
                                gasStation.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ) ||
                                gasStation.description.toLowerCase().contains(
                                  value.toLowerCase(),
                                ) ||
                                gasStation.fuelTypes.any(
                                  (fuel) => fuel.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                ) ||
                                (gasStation.address?.toLowerCase().contains(
                                      value.toLowerCase(),
                                    ) ??
                                    false),
                          )
                          .toList();
                    }
                  } else {
                    if (value.isEmpty) {
                      _filteredServices = List.from(_allServices);
                    } else {
                      _filteredServices = _allServices
                          .where(
                            (service) =>
                                service.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ) ||
                                service.description.toLowerCase().contains(
                                  value.toLowerCase(),
                                ) ||
                                service.services.any(
                                  (serviceItem) => serviceItem
                                      .toLowerCase()
                                      .contains(value.toLowerCase()),
                                ) ||
                                (service.address?.toLowerCase().contains(
                                      value.toLowerCase(),
                                    ) ??
                                    false),
                          )
                          .toList();
                    }
                  }
                });
                _updateMapObjects();
              },
              onFilterTap: _openFilterSheet,
            ),
          ),

          // Переключатель автосервисы/заправки - скрываем когда показан маршрут или навигация
          if (_routePolyline == null && !_isNavigating)
            Positioned(
              top: 0,
              right: 16,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Очищаем маршрут при переключении на автосервисы
                          if (_routePolyline != null) {
                            _clearRoute();
                          }
                          setState(() {
                            _showGasStations = false;
                            _searchQuery = '';
                          });
                          _updateMapObjects();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !_showGasStations
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.build_circle_outlined,
                            color: !_showGasStations
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Очищаем маршрут при переключении на заправки
                          if (_routePolyline != null) {
                            _clearRoute();
                          }
                          setState(() {
                            _showGasStations = true;
                            _searchQuery = '';
                          });
                          _updateMapObjects();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _showGasStations
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.local_gas_station_outlined,
                            color: _showGasStations
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Кнопка "Мое местоположение" в стиле Яндекс Карт
          // Показываем только если НЕ идет навигация И НЕ показана панель выбора маршрута
          if (!_isNavigating &&
              !(_routePolyline != null && _availableRoutes.isNotEmpty))
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 20,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1.0,
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Stack(
                      children: [
                        Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          child: InkWell(
                            onTap: _determinePosition,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.navigation,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
