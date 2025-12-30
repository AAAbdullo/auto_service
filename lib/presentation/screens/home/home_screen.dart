import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/widgets/common/loading_overlay.dart';
import 'package:auto_service/core/services/mapkit_routing_service.dart';
import 'package:auto_service/core/services/yandex_router_api_service.dart';
import 'package:auto_service/core/services/navigation_service.dart';
import 'package:auto_service/presentation/widgets/navigation_panel.dart';
import 'package:auto_service/presentation/widgets/unified_search_bar.dart';

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

  Point? _currentPosition;
  double _selectedRating = 0.0;
  final List<String> _selectedCategories = [];
  String _searchQuery = '';
  RouteType _selectedRouteType = RouteType.driving; // Тип маршрута

  final List<MapObject> _mapObjects = [];

  BitmapDescriptor? _serviceAssetIcon;

  // Категории (используются для фильтрации)
  List<String> get _categories => [
    'diagnostics',
    'engine_repair',
    'oil_change',
    'tire_service',
    'brake_repair',
    'painting',
    'tuning',
    'car_wash',
    'ac_repair',
    'transmission_repair',
  ];

  // Навигация
  final NavigationService _navigationService = NavigationService();
  NavigationState? _navigationState;
  RouteResult? _currentRoute;
  Point? _routeDestination;
  Timer? _cameraFollowTimer;
  bool _ttsEnabled = true; // TTS включен по умолчанию

  // Nearest services on map
  bool _isNearestModeOnMap = false;
  final double _mapNearestRadius = 5000; // 5 км по умолчанию

  // Умное поведение камеры (как в Яндекс.Картах)
  Timer? _cameraReturnTimer;
  bool _userInteractingWithMap = false;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Слушаем изменения статуса сервиса геолокации (вкл/выкл GPS)
    _serviceStatusStreamSubscription = Geolocator.getServiceStatusStream()
        .listen((ServiceStatus status) {
          if (status == ServiceStatus.enabled) {
            debugPrint('📍 GPS включен, перезапускаем определение позиции...');
            _determinePosition();
          }
        });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureMarkerAssetsLoaded();
      if (mounted) {
        _updateMapObjects();
      }
    });
    _loadNearbyServices();
    _determinePosition();
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    _cameraFollowTimer?.cancel();
    _cameraReturnTimer?.cancel();
    _navigationService.stopNavigation();
    super.dispose();
  }

  // Метод для построения маршрута (вызывается из main.dart)
  Future<void> buildRouteTo(double latitude, double longitude) async {
    if (!mounted || _currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Не удалось определить ваше местоположение'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      // Строим маршрут с таймаутом
      final result =
          await MapKitRoutingService.buildRoute(
            startPoint: _currentPosition!,
            endPoint: Point(latitude: latitude, longitude: longitude),
            routeType: _selectedRouteType,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Route building timeout');
            },
          );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('route_error'.tr())),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Повторить',
                textColor: Colors.white,
                onPressed: () => buildRouteTo(latitude, longitude),
              ),
            ),
          );
        }
        return;
      }

      // Добавляем линию маршрута на карту
      if (mounted) {
        setState(() {
          _mapObjects.removeWhere((obj) => obj.mapId.value == 'route_line');
          _mapObjects.add(
            PolylineMapObject(
              mapId: const MapObjectId('route_line'),
              polyline: Polyline(points: result.geometryPoints),
              strokeColor: _getRouteColor(_selectedRouteType),
              strokeWidth: 5.0,
              outlineColor: Colors.white,
              outlineWidth: 1.0,
            ),
          );

          // Сохраняем маршрут и точку назначения для кнопки "Начать навигацию"
          _currentRoute = result;
          _routeDestination = Point(latitude: latitude, longitude: longitude);

          // Логируем сохранённые данные маршрута
          debugPrint('💾 Сохранён маршрут:');
          debugPrint(
            '   Расстояние: ${result.distanceKm.toStringAsFixed(1)} км',
          );
          debugPrint('   Время: ${result.durationMinutes} мин');
          debugPrint('   С пробками: ${result.durationWithTrafficMinutes} мин');
        });

        // Приближаем камеру к маршруту
        if (_mapController != null && result.geometryPoints.isNotEmpty) {
          final points = result.geometryPoints;
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

          await _mapController!.moveCamera(
            CameraUpdate.newGeometry(
              Geometry.fromBoundingBox(
                BoundingBox(
                  southWest: Point(latitude: minLat, longitude: minLon),
                  northEast: Point(latitude: maxLat, longitude: maxLon),
                ),
              ),
            ),
            animation: const MapAnimation(
              type: MapAnimationType.smooth,
              duration: 1.0,
            ),
          );
        }
      }
    } on TimeoutException catch (_) {
      debugPrint('⏱️ Таймаут построения маршрута');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.timer_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Превышено время ожидания. Проверьте интернет.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => buildRouteTo(latitude, longitude),
            ),
          ),
        );
      }
    } on SocketException catch (_) {
      debugPrint('🌐 Ошибка сети при построении маршрута');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Нет подключения к интернету')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => buildRouteTo(latitude, longitude),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка построения маршрута: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('route_error'.tr())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => buildRouteTo(latitude, longitude),
            ),
          ),
        );
      }
    }
  }

  /// Публичный метод для обновления списка сервисов (вызывается из других экранов)
  Future<void> refreshServices() async {
    debugPrint('🔄 Обновление списка сервисов...');
    await _loadNearbyServices();
  }

  /// Получить цвет маршрута в зависимости от типа
  Color _getRouteColor(RouteType type) {
    switch (type) {
      case RouteType.driving:
        return Colors.blue;
      case RouteType.walking:
        return Colors.green;
    }
  }

  /// Начать навигацию
  Future<void> _startNavigation() async {
    if (_currentRoute == null || _routeDestination == null) return;

    debugPrint('🚀 Начало навигации с маршрутом:');
    debugPrint(
      '   Расстояние: ${_currentRoute!.distanceKm.toStringAsFixed(1)} км',
    );
    debugPrint('   Время: ${_currentRoute!.durationMinutes} мин');
    debugPrint(
      '   С пробками: ${_currentRoute!.durationWithTrafficMinutes} мин',
    );

    await _navigationService.startNavigation(
      route: _currentRoute!,
      destination: _routeDestination!,
      ttsEnabled: _ttsEnabled, // Передаем состояние TTS
      onUpdate: (state) {
        if (mounted) {
          setState(() {
            _navigationState = state;

            // Обновить линию маршрута с оставшимися точками (прогрессивная очистка)
            if (state.remainingRoutePoints.isNotEmpty) {
              _mapObjects.removeWhere((obj) => obj.mapId.value == 'route_line');
              _mapObjects.add(
                PolylineMapObject(
                  mapId: const MapObjectId('route_line'),
                  polyline: Polyline(points: state.remainingRoutePoints),
                  strokeColor: _getRouteColor(_selectedRouteType),
                  strokeWidth: 5.0,
                  outlineColor: Colors.white,
                  outlineWidth: 1.0,
                ),
              );
            }
          });

          // Обновить камеру в режиме следования
          _updateCameraFollowing();
        }
      },
      onArrival: () {
        // Очистить маршрут с карты при автоматическом завершении навигации
        if (mounted) {
          setState(() {
            _mapObjects.removeWhere((obj) => obj.mapId.value == 'route_line');
            _currentRoute = null;
            _routeDestination = null;
          });
          debugPrint('🎯 Прибыли к цели! Маршрут очищен с карты.');
        }
      },
    );

    // Запустить таймер для плавного следования камеры (каждые 5 секунд)
    _cameraFollowTimer = Timer.periodic(
      const Duration(seconds: 5), // Очень плавное обновление
      (_) => _updateCameraFollowing(),
    );
  }

  /// Остановить навигацию
  Future<void> _stopNavigation() async {
    await _navigationService.stopNavigation();
    _cameraFollowTimer?.cancel();
    _cameraFollowTimer = null;

    if (mounted) {
      setState(() {
        _navigationState = null;
        // НЕ удаляем _currentRoute и _routeDestination!
        // Маршрут остается на карте, пользователь может:
        // - Переключить тип маршрута
        // - Снова начать навигацию
        // - Изучить маршрут
        // Только кнопка "X" (отмена) удаляет маршрут
      });
    }
  }

  /// Обновить камеру в режиме следования
  void _updateCameraFollowing() {
    if (_mapController == null || !_navigationService.isNavigating) return;

    // Не обновлять камеру, если пользователь взаимодействует с картой
    if (_userInteractingWithMap) return;

    final cameraPos = _navigationService.getFollowingCameraPosition();
    if (cameraPos != null) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(cameraPos),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 2.5, // Очень плавная анимация
        ),
      );
    }
  }

  /// Обработка начала взаимодействия пользователя с картой
  void _onMapTapDown() {
    if (!mounted) return;
    _userInteractingWithMap = true;
    _cameraReturnTimer?.cancel();
  }

  /// Обработка окончания взаимодействия пользователя с картой
  void _onMapTapUp() {
    if (!mounted) return;
    _userInteractingWithMap = false;

    // Запустить таймер для возврата камеры через 5 секунд
    if (_navigationService.isNavigating) {
      _cameraReturnTimer?.cancel();
      _cameraReturnTimer = Timer(const Duration(seconds: 5), () {
        if (!_userInteractingWithMap &&
            _navigationService.isNavigating &&
            mounted) {
          _updateCameraFollowing();
        }
      });
    }
  }

  Future<void> _ensureMarkerAssetsLoaded() async {
    try {
      if (_serviceAssetIcon == null) {
        final ByteData data = await rootBundle.load(
          'assets/icons/auto_service.png',
        );
        _serviceAssetIcon = BitmapDescriptor.fromBytes(
          data.buffer.asUint8List(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки иконок: $e');
    }
  }

  Future<void> _loadNearbyServices() async {
    try {
      final repo = AutoServicesRepository();
      final services = await repo.getAllServices();

      debugPrint(
        '\n🔍 ========== ЗАГРУЖЕНО СЕРВИСОВ: ${services.length} ==========',
      );
      for (var service in services) {
        debugPrint('📍 Сервис: ${service.name} (ID: ${service.id})');
        debugPrint('   Координаты: ${service.latitude}, ${service.longitude}');
        debugPrint('   Статус: ${service.status}');
        debugPrint('   Активен: ${service.isActive}');
        debugPrint('   Картинок: ${service.images.length}');
        if (service.images.isNotEmpty) {
          for (var img in service.images) {
            debugPrint('      - image: ${img.image}');
            debugPrint('      - image_url: ${img.imageUrl}');
            debugPrint('      - full URL: ${img.getFullImageUrl()}');
          }
        } else {
          debugPrint('   ⚠️ НЕТ КАРТИНОК!');
        }
        if (service.imageUrl != null) {
          debugPrint('   imageUrl (legacy): ${service.imageUrl}');
        }
      }
      debugPrint('🔍 ====================================\n');

      if (mounted) {
        setState(() {
          _allServices = services;
          _filteredServices = services;
        });
        _updateMapObjects();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки сервисов: $e');
    }
  }

  Future<void> _determinePosition() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      // 1. Проверяем сервис, но НЕ выходим, если выключено.
      // Приложение попытается запросить права, и если пользователь включит GPS позже,
      // сработает StreamSubscription (см. initState).
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
          '⚠️ Location service is disabled, but continuing to check permissions...',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentPosition = const Point(
                latitude: 41.2995,
                longitude: 69.2401,
              );
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentPosition = const Point(
              latitude: 41.2995,
              longitude: 69.2401,
            );
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Включаем слой местоположения после получения разрешения
      if (_mapController != null) {
        try {
          await _mapController!.toggleUserLayer(visible: true);
        } catch (e) {
          debugPrint('Ошибка включения слоя местоположения: $e');
        }
      }

      Position? position;
      try {
        // Пробуем получить точное местоположение
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint(
          '⚠️ Ошибка получения точной позиции, пробуем последнюю известную: $e',
        );
        // Fallback: пробуем получить последнее известное местоположение
        position = await Geolocator.getLastKnownPosition();
      }

      if (mounted) {
        if (position != null) {
          setState(() {
            _currentPosition = Point(
              latitude: position!.latitude,
              longitude: position.longitude,
            );
            _isLoadingLocation = false;
          });
          _updateMapObjects();
          _moveToCurrentLocation();

          // Гарантированно включаем слой ПОСЛЕ получения позиции,
          // так как на некоторых версиях SDK он может не включиться сразу
          if (_mapController != null) {
            try {
              await _mapController!.toggleUserLayer(visible: true);
            } catch (_) {}
          }
        } else {
          debugPrint(
            '❌ Не удалось определить местоположение (ни точное, ни последнее)',
          );
          setState(() {
            _currentPosition = const Point(
              latitude: 41.2995,
              longitude: 69.2401,
            );
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка определения местоположения: $e');
      if (mounted) {
        setState(() {
          _currentPosition = const Point(latitude: 41.2995, longitude: 69.2401);
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 14),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );
    }
  }

  void _updateMapObjects() async {
    _mapObjects.clear();

    // Метка пользователя теперь управляется через UserLocationLayer
    // Не добавляем вручную PlacemarkMapObject для местоположения

    // Добавляем маркеры сервисов
    if (_filteredServices.isNotEmpty) {
      debugPrint('\n🗺️ ========== ДОБАВЛЕНИЕ МАРКЕРОВ НА КАРТУ ==========');
      debugPrint('📊 Всего сервисов: ${_allServices.length}');
      debugPrint('📊 После фильтрации: ${_filteredServices.length}');

      try {
        // Загружаем иконку auto_service.png
        final ByteData imageData = await rootBundle.load(
          'assets/icons/auto_service.png',
        );
        final Uint8List imageBytes = imageData.buffer.asUint8List();
        final serviceIcon = BitmapDescriptor.fromBytes(imageBytes);

        for (int i = 0; i < _filteredServices.length; i++) {
          final service = _filteredServices[i];
          debugPrint(
            '   ✅ Добавлен маркер: ${service.name} (${service.latitude}, ${service.longitude})',
          );
          _mapObjects.add(
            PlacemarkMapObject(
              mapId: MapObjectId('service_$i'),
              point: Point(
                latitude: service.latitude,
                longitude: service.longitude,
              ),
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(image: serviceIcon, scale: 0.15),
              ),
              opacity: 1.0,
              onTap: (PlacemarkMapObject self, Point point) {
                _onServiceTap(service);
              },
            ),
          );
        }
        debugPrint('🗺️ ============================================\n');
      } catch (e) {
        debugPrint('Ошибка загрузки иконки auto_service.png: $e');
        // Fallback на стандартную иконку
        for (int i = 0; i < _filteredServices.length; i++) {
          final service = _filteredServices[i];
          _mapObjects.add(
            PlacemarkMapObject(
              mapId: MapObjectId('service_$i'),
              point: Point(
                latitude: service.latitude,
                longitude: service.longitude,
              ),
              opacity: 1.0,
              onTap: (PlacemarkMapObject self, Point point) {
                _onServiceTap(service);
              },
            ),
          );
        }
      }
    } else {
      debugPrint('\n⚠️ НЕТ СЕРВИСОВ ДЛЯ ОТОБРАЖЕНИЯ НА КАРТЕ!\n');
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Helper method to build service image
  Widget _buildServiceImage(AutoServiceModel service) {
    String? imageUrl;

    // 1. Try to get from images list
    if (service.images.isNotEmpty) {
      imageUrl = service.images.first.getFullImageUrl();
    }
    // 2. Fallback to imageUrl property if available
    else if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
      var url = service.imageUrl!;
      if (!url.startsWith('http')) {
        url = 'https://avtomakon.airi.uz$url';
      }
      imageUrl = url;
    }

    if (imageUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error_outline, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'filters'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating Filter
                          Text(
                            'rating'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [3, 4, 5].map((rating) {
                              return ChoiceChip(
                                label: Text('$rating+'),
                                selected: _selectedRating == rating.toDouble(),
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedRating = selected
                                        ? rating.toDouble()
                                        : 0.0;
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Services Filter
                          Text(
                            'services_title'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _categories.map((categorySlug) {
                              final isSelected = _selectedCategories.contains(
                                categorySlug,
                              );
                              return ChoiceChip(
                                label: Text(categorySlug.tr()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      _selectedCategories.add(categorySlug);
                                    } else {
                                      _selectedCategories.remove(categorySlug);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedRating = 0.0;
                            _selectedCategories.clear();
                          });
                        },
                        child: Text('clear'.tr()),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        child: Text('apply'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onServiceTap(AutoServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow taller content
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Service Image
              _buildServiceImage(service),

              Row(
                children: [
                  const Icon(Icons.car_repair, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(service.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  if (service.phone != null && service.phone!.isNotEmpty) ...[
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(service.phone!),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  buildRouteTo(service.latitude, service.longitude);
                },
                icon: const Icon(Icons.directions),
                label: Text('route'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    debugPrint('🔎 Applying filters...');
    debugPrint('   Rating: $_selectedRating');
    debugPrint('   Categories: ${_selectedCategories.join(', ')}');
    debugPrint('   Search: $_searchQuery');

    setState(() {
      _filteredServices = _allServices.where((service) {
        // Filter by rating
        final matchesRating = service.rating >= _selectedRating;

        // Filter by category
        final matchesCategory =
            _selectedCategories.isEmpty ||
            _selectedCategories.any(
              (category) =>
                  // Match by slug
                  service.category?.slug == category ||
                  // Match by category name (case-insensitive)
                  (service.category?.name.toLowerCase() ==
                      category.toLowerCase()) ||
                  // Search in services strings
                  service.services.any(
                    (s) =>
                        s.toLowerCase().contains(category.toLowerCase()) ||
                        category.toLowerCase().contains(s.toLowerCase()),
                  ) ||
                  // Search in extraServices objects
                  (service.extraServices?.any(
                        (es) =>
                            es.name.toLowerCase().contains(
                              category.toLowerCase(),
                            ) ||
                            category.toLowerCase().contains(
                              es.name.toLowerCase(),
                            ),
                      ) ??
                      false),
            );

        // Search in name or description
        final matchesSearch =
            _searchQuery.isEmpty ||
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            // Also search in extra services
            (service.extraServices?.any(
                  (es) => es.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                ) ??
                false);

        return matchesRating && matchesCategory && matchesSearch;
      }).toList();
    });

    debugPrint('✅ Filtered services: ${_filteredServices.length}');
    _updateMapObjects();
  }

  /// Загрузить ближайшие сервисы на карте
  Future<void> _loadNearestServicesOnMap() async {
    if (_currentPosition == null) {
      // Запросить разрешение на геолокацию
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('location_permission_required'.tr())),
            );
          }
          return;
        }
      }

      // Получить текущую позицию
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = Point(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });
      } catch (e) {
        debugPrint('❌ Ошибка получения позиции: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('failed_to_get_location'.tr())),
          );
        }
        return;
      }
    }

    // Загрузить ближайшие сервисы
    try {
      final services = await AutoServicesRepository().getNearestServices(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        radius: _mapNearestRadius,
      );

      setState(() {
        _isNearestModeOnMap = true;
        _allServices = services;
        _filteredServices = services;
      });

      _updateMapObjects();
      debugPrint('✅ Загружено ${services.length} ближайших сервисов на карте');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ближайших сервисов: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_load_nearest_services'.tr())),
        );
      }
    }
  }

  /// Переключиться на все сервисы
  Future<void> _switchToAllServicesOnMap() async {
    setState(() {
      _isNearestModeOnMap = false;
    });
    // Перезагрузить все сервисы
    try {
      final services = await AutoServicesRepository().getAllServices();
      setState(() {
        _allServices = services;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки сервисов: $e');
    }
  }

  /// Обработчик кнопки "Ближайшие" на карте
  void _handleNearestTapOnMap() {
    if (_isNearestModeOnMap) {
      _switchToAllServicesOnMap();
    } else {
      _loadNearestServicesOnMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _mapObjects,
            onMapCreated: (controller) async {
              _mapController = controller;

              // Включаем слой местоположения, только если есть разрешение
              LocationPermission permission =
                  await Geolocator.checkPermission();
              if (permission == LocationPermission.always ||
                  permission == LocationPermission.whileInUse) {
                try {
                  await controller.toggleUserLayer(visible: true);
                } catch (e) {
                  debugPrint('Ошибка включения слоя местоположения: $e');
                }
              }

              if (_currentPosition != null) {
                await _moveToCurrentLocation();
              }
            },
            onCameraPositionChanged: (cameraPosition, reason, finished) {
              // Если камера двигается из-за пользователя (не программно)
              if (reason == CameraUpdateReason.gestures) {
                _onMapTapDown();

                // Если жест завершен
                if (finished) {
                  _onMapTapUp();
                }
              }
            },
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: UnifiedSearchBar(
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() => _searchQuery = query);
                _applyFilters();
              },
              onNearestTap: _handleNearestTapOnMap,
              onFilterTap: _showFilterDialog,
              isNearestMode: _isNearestModeOnMap,
              hasActiveFilters:
                  _selectedRating > 0 || _selectedCategories.isNotEmpty,
              hintText: 'search'.tr(),
            ),
          ),

          // Кнопка "Моя локация" (когда нет маршрута)
          if (_currentRoute == null && _navigationState == null)
            Positioned(
              bottom: 24,
              right: 16,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _moveToCurrentLocation,
                    borderRadius: BorderRadius.circular(16),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          // Объединенная панель управления в стиле Яндекс.Карт (когда есть маршрут)
          if (_currentRoute != null && _navigationState == null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1C)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.3
                            : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Селектор типа маршрута сверху (на всю ширину)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Row(
                        children: [
                          // Кнопка "На машине"
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRouteType = RouteType.driving;
                                });
                                if (_routeDestination != null) {
                                  buildRouteTo(
                                    _routeDestination!.latitude,
                                    _routeDestination!.longitude,
                                  );
                                }
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedRouteType == RouteType.driving
                                      ? _getRouteColor(RouteType.driving)
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      color:
                                          _selectedRouteType ==
                                              RouteType.driving
                                          ? Colors.white
                                          : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'На машине',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _selectedRouteType ==
                                                RouteType.driving
                                            ? Colors.white
                                            : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Кнопка "Пешком"
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRouteType = RouteType.walking;
                                });
                                if (_routeDestination != null) {
                                  buildRouteTo(
                                    _routeDestination!.latitude,
                                    _routeDestination!.longitude,
                                  );
                                }
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedRouteType == RouteType.walking
                                      ? _getRouteColor(RouteType.walking)
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_walk,
                                      color:
                                          _selectedRouteType ==
                                              RouteType.walking
                                          ? Colors.white
                                          : (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Пешком',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _selectedRouteType ==
                                                RouteType.walking
                                            ? Colors.white
                                            : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Разделитель
                    Container(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                    ),

                    // Кнопки действий
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Кнопка начать навигацию
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getRouteColor(_selectedRouteType),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _startNavigation,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.navigation,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Поехали',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Кнопка моей локации
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _moveToCurrentLocation,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.my_location,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  size: 22,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Кнопка отмены
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentRoute = null;
                                  _routeDestination = null;
                                  _mapObjects.removeWhere(
                                    (obj) => obj.mapId.value == 'route_line',
                                  );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Маршрут отменен'),
                                      ],
                                    ),
                                    backgroundColor: Colors.grey[800],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Панель навигации (показывается при активной навигации)
          if (_navigationState != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NavigationPanel(
                navigationState: _navigationState!,
                onStop: _stopNavigation,
                ttsEnabled: _ttsEnabled,
                onTTSToggle: () {
                  setState(() {
                    _ttsEnabled = !_ttsEnabled;
                  });
                  // Обновить состояние TTS в NavigationService
                  _navigationService.setTTSEnabled(_ttsEnabled);
                },
              ),
            ),

          if (_isLoadingLocation)
            LoadingOverlay(
              isLoading: _isLoadingLocation,
              message: 'Определение местоположения...',
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
