import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/widgets/common/loading_overlay.dart';
import 'package:auto_service/presentation/widgets/custom_search_bar.dart';
import 'package:auto_service/core/services/mapkit_routing_service.dart';
import 'package:auto_service/core/services/mapkit_native_routing_service.dart';
import 'package:auto_service/core/services/yandex_router_api_service.dart';
import 'package:auto_service/core/services/navigation_service.dart';
import 'package:auto_service/core/services/tts_service.dart';
import 'package:auto_service/presentation/widgets/navigation_panel.dart';
import 'package:auto_service/presentation/widgets/route_type_selector.dart';

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
  String? _selectedCategory;
  String _searchQuery = '';
  RouteType _selectedRouteType = RouteType.driving; // Тип маршрута

  final List<MapObject> _mapObjects = [];

  BitmapDescriptor? _serviceAssetIcon;

  // Навигация
  final NavigationService _navigationService = NavigationService();
  NavigationState? _navigationState;
  RouteResult? _currentRoute;
  Point? _routeDestination;
  Timer? _cameraFollowTimer;
  bool _ttsEnabled = true; // TTS включен по умолчанию

  @override
  void initState() {
    super.initState();
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
    _cameraFollowTimer?.cancel();
    _navigationService.stopNavigation();
    super.dispose();
  }

  // Метод для построения маршрута (вызывается из main.dart)
  Future<void> buildRouteTo(double latitude, double longitude) async {
    if (!mounted || _currentPosition == null) return;

    try {
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('building_route'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );

      // Строим маршрут через нативный SDK
      RouteResult? result;

      if (_selectedRouteType == RouteType.driving) {
        // Автомобильный маршрут через нативный SDK
        final routes = await MapKitNativeRoutingService.buildDrivingRoute(
          startPoint: _currentPosition!,
          endPoint: Point(latitude: latitude, longitude: longitude),
          routesCount: 1,
        );

        if (routes.isNotEmpty) {
          result = RouteResult.fromDrivingRoute(routes.first);
        }
      } else {
        // Пешеходный маршрут через нативный SDK
        final bicycleResult =
            await MapKitNativeRoutingService.buildWalkingRoute(
              startPoint: _currentPosition!,
              endPoint: Point(latitude: latitude, longitude: longitude),
            );

        if (bicycleResult != null &&
            bicycleResult.routes != null &&
            bicycleResult.routes!.isNotEmpty) {
          result = RouteResult.fromMasstransitRoute(
            bicycleResult.routes!.first,
          );
        }
      }

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('route_error'.tr()),
              backgroundColor: Colors.red,
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
              polyline: Polyline(points: result!.geometryPoints),
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

        // Показываем информацию о маршруте
        final routeInfo = _selectedRouteType == RouteType.driving
            ? '${result.formattedDistance}, ${result.formattedDurationWithTraffic} (с пробками)'
            : '${result.formattedDistance}, ${result.formattedDuration}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedRouteType.emoji} ${'route'.tr()}: $routeInfo',
            ),
            backgroundColor: _getRouteColor(_selectedRouteType),
            duration: const Duration(seconds: 5),
          ),
        );

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
    } catch (e) {
      debugPrint('Ошибка построения маршрута: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('route_error'.tr()),
            backgroundColor: Colors.red,
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
      onUpdate: (state) {
        if (mounted) {
          setState(() {
            _navigationState = state;
          });

          // Обновить камеру в режиме следования
          _updateCameraFollowing();
        }
      },
    );

    // Запустить таймер для плавного следования камеры
    _cameraFollowTimer = Timer.periodic(
      const Duration(milliseconds: 500),
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
        _currentRoute = null;
        _routeDestination = null;

        // Удалить линию маршрута
        _mapObjects.removeWhere((obj) => obj.mapId.value == 'route_line');
      });
    }
  }

  /// Обновить камеру в режиме следования
  void _updateCameraFollowing() {
    if (_mapController == null || !_navigationService.isNavigating) return;

    final cameraPos = _navigationService.getFollowingCameraPosition();
    if (cameraPos != null) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(cameraPos),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = Point(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _isLoadingLocation = false;
        });
        _updateMapObjects();
        _moveToCurrentLocation();
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
              height:
                  MediaQuery.of(context).size.height *
                  0.5, // Half screen height
              child: Column(
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

                  // Category Filter (Simplified for now - can be expanded)
                  // For now we just filter by known categories if needed, or stick to rating as primary filter on map
                  const Spacer(),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedRating = 0.0;
                            _selectedCategory = null;
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
    setState(() {
      _filteredServices = _allServices.where((service) {
        final matchesRating =
            _selectedRating == 0.0 || service.rating >= _selectedRating;
        final matchesCategory =
            _selectedCategory == null ||
            service.category?.slug == _selectedCategory;
        final matchesSearch =
            _searchQuery.isEmpty ||
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        return matchesRating && matchesCategory && matchesSearch;
      }).toList();
    });
    _updateMapObjects();
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

              // Включаем слой местоположения пользователя с встроенными иконками Яндекса
              await controller.toggleUserLayer(visible: true);

              if (_currentPosition != null) {
                await _moveToCurrentLocation();
              }
            },
          ),

          // Поисковая панель
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: CustomSearchBar(
              hintText: 'search'.tr(),
              onChanged: (query) {
                setState(() => _searchQuery = query);
                _applyFilters();
              },
              onFilterTap: () {
                _showFilterDialog();
              },
            ),
          ),

          // Кнопка "Моя локация" (скрывается во время навигации)
          if (_navigationState == null)
            Positioned(
              bottom: _currentRoute != null ? 180 : 120,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'location',
                onPressed: _moveToCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

          // Селектор типа маршрута (показывается только после построения маршрута)
          if (_currentRoute != null && _navigationState == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: RouteTypeSelector(
                selectedType: _selectedRouteType,
                onTypeSelected: (type) {
                  setState(() {
                    _selectedRouteType = type;
                  });

                  // Перестроить маршрут с новым типом
                  if (_routeDestination != null) {
                    buildRouteTo(
                      _routeDestination!.latitude,
                      _routeDestination!.longitude,
                    );
                  }
                },
              ),
            ),

          // Кнопка "Начать навигацию" (показывается после построения маршрута)
          if (_currentRoute != null && _navigationState == null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Кнопка начать навигацию
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRouteColor(_selectedRouteType),
                            _getRouteColor(_selectedRouteType).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _startNavigation,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Начать навигацию',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Кнопка отмены маршрута
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
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
                            const SnackBar(
                              content: Text('Маршрут отменен'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  if (!_ttsEnabled) {
                    TTSService().stop();
                  }
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
