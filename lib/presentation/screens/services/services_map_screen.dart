import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/presentation/screens/services/service_detail_screen.dart';
import 'package:auto_service/presentation/providers/theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:auto_service/core/services/mapkit_driving_service.dart';

class ServicesMapScreen extends StatefulWidget {
  final List<AutoServiceModel> services;

  const ServicesMapScreen({super.key, required this.services});

  @override
  State<ServicesMapScreen> createState() => _ServicesMapScreenState();
}

class _ServicesMapScreenState extends State<ServicesMapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  AutoServiceModel? _selectedService;
  bool _showServices = true;

  @override
  void initState() {
    super.initState();
    // Инициализируем MapKit Driving Service
    MapKitDrivingService.initialize();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _addServiceMarkers();
    await _addUserLocationMarker();

    // Слушаем изменения темы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _setMapTheme(themeProvider.isDarkMode);
    });
  }

  void _setMapTheme(bool isDarkMode) {
    if (_mapController != null) {
      try {
        debugPrint('Setting map theme: ${isDarkMode ? "dark" : "light"}');
      } catch (e) {
        debugPrint('Error setting map theme: $e');
      }
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
    IconData icon,
    Color color,
    String text,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(120, 150);

    // Рисуем тень
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(size.width / 2, size.height - 30),
      25,
      shadowPaint,
    );

    // Рисуем основную метку (каплю)
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    path.addOval(Rect.fromCircle(center: center, radius: 30));
    path.moveTo(size.width / 2, size.height / 2 + 30);
    path.lineTo(size.width / 2 - 10, size.height - 30);
    path.lineTo(size.width / 2 + 10, size.height - 30);
    path.close();

    // Заливка метки
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Обводка метки
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);

    // Рисуем иконку
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 32,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
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
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _addServiceMarkers() async {
    if (!_showServices) return;

    final markerIcon = await _createCustomMarker(
      Icons.car_repair,
      Colors.blue,
      'S',
    );

    for (final service in widget.services) {
      _mapObjects.add(
        PlacemarkMapObject(
          mapId: MapObjectId('service_${service.id}'),
          point: Point(
            latitude: service.latitude,
            longitude: service.longitude,
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: markerIcon, scale: 0.8),
          ),
          opacity: 1.0,
          onTap: (PlacemarkMapObject self, Point point) {
            _onServiceTap(service);
          },
        ),
      );
    }

    // Автоматически центрируем карту при инициализации
    if (_mapObjects.isNotEmpty && _mapController != null) {
      await _fitMarkers();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fitMarkers() async {
    if (_mapObjects.isEmpty || _mapController == null) return;

    debugPrint('Fitting camera to ${_mapObjects.length} markers');

    double minLat = 90.0, maxLat = -90.0;
    double minLon = 180.0, maxLon = -180.0;
    bool hasPoints = false;

    for (final obj in _mapObjects) {
      if (obj is PlacemarkMapObject) {
        final p = obj.point;
        if (p.latitude != 0 && p.longitude != 0) {
          minLat = p.latitude < minLat ? p.latitude : minLat;
          maxLat = p.latitude > maxLat ? p.latitude : maxLat;
          minLon = p.longitude < minLon ? p.longitude : minLon;
          maxLon = p.longitude > maxLon ? p.longitude : maxLon;
          hasPoints = true;
        }
      }
    }

    if (!hasPoints) return;

    // Если только одна точка, просто перемещаемся к ней
    if (minLat == maxLat && minLon == maxLon) {
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: minLat, longitude: minLon),
            zoom: 14,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );
      return;
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

  void _onServiceTap(AutoServiceModel service) {
    setState(() {
      _selectedService = service;
    });
  }

  Future<void> _toggleMarkers() async {
    _mapObjects.clear();
    await _addServiceMarkers();
    await _addUserLocationMarker();
  }

  Future<void> _buildRouteToService(AutoServiceModel service) async {
    try {
      final userLocation = await _getUserLocation();

      if (userLocation != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'route'.tr()}: ${service.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Удаляем старые маршруты
        setState(() {
          _mapObjects.removeWhere(
            (obj) => obj.mapId.value.startsWith('route_'),
          );
        });

        _requestRoutes(
          Point(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude,
          ),
          Point(latitude: service.latitude, longitude: service.longitude),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_not_available'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
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

  Future<void> _requestRoutes(Point from, Point to) async {
    try {
      // 🎯 Используем нативный Yandex MapKit Driving Router
      final result = await MapKitDrivingService.buildRoute(
        startPoint: from,
        endPoint: to,
        routesCount: 1,
      );

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

      // Форматируем расстояние и время
      final distanceKm = result.distanceKm.toStringAsFixed(1);
      final durationMin = result.durationWithTrafficMinutes;
      final distanceMetrics = '$distanceKm км';
      final durationMetrics = '$durationMin мин';

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'route'.tr()}: $distanceMetrics, $durationMetrics',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      setState(() {
        _mapObjects.removeWhere((obj) => obj.mapId.value == 'route_1');
        _mapObjects.add(
          PolylineMapObject(
            mapId: const MapObjectId('route_1'),
            polyline: Polyline(points: result.geometryPoints),
            strokeColor: Colors.blue[700]!,
            strokeWidth: 5.0,
            outlineColor: Colors.white,
            outlineWidth: 1.0,
          ),
        );
      });

      // Zoom to route
      final points = result.geometryPoints;
      if (points.isNotEmpty) {
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLon = points.first.longitude;
        double maxLon = points.first.longitude;

        for (final point in points) {
          minLat = minLat > point.latitude ? point.latitude : minLat;
          maxLat = maxLat < point.latitude ? point.latitude : maxLat;
          minLon = minLon > point.longitude ? point.longitude : minLon;
          maxLon = maxLon < point.longitude ? point.longitude : maxLon;
        }

        await _mapController?.moveCamera(
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
    } catch (e, stackTrace) {
      print('❌ Exception building route: $e');
      print('Stack trace: $stackTrace');
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

  Future<Point?> _getUserLocation() async {
    try {
      // Проверяем, включены ли службы геолокации
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
          '⚠️ Location services disabled - using Tashkent as fallback for emulator',
        );
        // Fallback: координаты Ташкента (для тестирования в эмуляторе)
        return const Point(latitude: 41.2995, longitude: 69.2401);
      }

      // Проверяем/запрашиваем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(
            '⚠️ Location permission denied - using Tashkent as fallback for emulator',
          );
          // Fallback для эмулятора
          return const Point(latitude: 41.2995, longitude: 69.2401);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          '⚠️ Location permission denied forever - using Tashkent as fallback for emulator',
        );
        // Fallback для эмулятора
        return const Point(latitude: 41.2995, longitude: 69.2401);
      }

      // Получаем текущее местоположение с разумным таймаутом
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      return Point(latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      debugPrint(
        '⚠️ Location error: $e - using Tashkent as fallback for emulator',
      );
      // Fallback при любой ошибке (идеально для эмулятора)
      return const Point(latitude: 41.2995, longitude: 69.2401);
    }
  }

  Future<void> _addUserLocationMarker() async {
    try {
      final location = await _getUserLocation();
      if (location == null) {
        debugPrint('⚠️ Unable to get user location');
        return;
      }

      // Загружаем изображение из assets
      final ByteData imageData = await DefaultAssetBundle.of(
        // ignore: use_build_context_synchronously
        context,
      ).load('assets/icons/geo_position.png');
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      final markerIcon = BitmapDescriptor.fromBytes(imageBytes);

      // Удаляем старый маркер пользователя, если есть
      _mapObjects.removeWhere(
        (obj) => obj.mapId == const MapObjectId('user_location'),
      );

      // Добавляем маркер пользователя
      _mapObjects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('user_location'),
          point: location,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: markerIcon, scale: 0.5),
          ),
          opacity: 1.0,
        ),
      );

      if (mounted) {
        setState(() {});
      }
      debugPrint(
        '✅ User location marker added at ${location.latitude}, ${location.longitude}',
      );
    } catch (e) {
      debugPrint('Error adding user location marker: $e');
    }
  }

  Future<void> _moveToUserLocation() async {
    if (_mapController == null) return;

    try {
      final location = await _getUserLocation();

      // С обновленным _getUserLocation(), это практически невозможно,
      // но оставляем проверку на безопасность
      if (location == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_not_available'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('showing_your_location'.tr()),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error moving to user location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_showing_location'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('services_map'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) async {
              setState(() {
                if (value == 'services') {
                  _showServices = !_showServices;
                }
              });
              await _toggleMarkers();
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'services',
                checked: _showServices,
                child: Row(
                  children: [
                    const Icon(Icons.car_repair, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('show_services'.tr()),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _mapObjects,
            onMapCreated: (YandexMapController controller) async {
              _mapController = controller;
              _setMapTheme(context.read<ThemeProvider>().isDarkMode);
              // После создания контроллера пробуем еще раз подогнать камеру
              if (_mapObjects.isNotEmpty) {
                await _fitMarkers();
              }
            },
          ),
          if (_selectedService != null) ...[
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.car_repair,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedService!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedService = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedService!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _selectedService!.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailScreen(
                                    service: _selectedService!,
                                  ),
                                ),
                              );

                              if (result != null &&
                                  result['buildRoute'] == true) {
                                _buildRouteToService(_selectedService!);
                              }
                            },
                            icon: const Icon(Icons.info),
                            label: Text('details'.tr()),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _buildRouteToService(_selectedService!),
                            icon: const Icon(Icons.directions),
                            label: Text('route'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Легенда в правом верхнем углу
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showServices)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.car_repair,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'services'.tr(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
