import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/models/gas_station_model.dart';
import 'package:auto_service/presentation/screens/services/service_detail_screen.dart';
import 'package:auto_service/presentation/providers/theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ServicesMapScreen extends StatefulWidget {
  final List<AutoServiceModel> services;
  final List<GasStationModel>? gasStations;

  const ServicesMapScreen({
    super.key,
    required this.services,
    this.gasStations,
  });

  @override
  State<ServicesMapScreen> createState() => _ServicesMapScreenState();
}

class _ServicesMapScreenState extends State<ServicesMapScreen> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  AutoServiceModel? _selectedService;
  GasStationModel? _selectedGasStation;
  bool _showServices = true;
  bool _showGasStations = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _addServiceMarkers();
    if (widget.gasStations != null) {
      await _addGasStationMarkers();
    }
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
        // TODO: Реализовать когда API будет доступно
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

    for (int i = 0; i < widget.services.length; i++) {
      final service = widget.services[i];

      _mapObjects.add(
        PlacemarkMapObject(
          mapId: MapObjectId('service_$i'),
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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addGasStationMarkers() async {
    if (!_showGasStations || widget.gasStations == null) return;

    final markerIcon = await _createCustomMarker(
      Icons.local_gas_station,
      Colors.green,
      'G',
    );

    for (int i = 0; i < widget.gasStations!.length; i++) {
      final station = widget.gasStations![i];

      _mapObjects.add(
        PlacemarkMapObject(
          mapId: MapObjectId('gas_station_$i'),
          point: Point(
            latitude: station.latitude,
            longitude: station.longitude,
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: markerIcon, scale: 0.8),
          ),
          opacity: 1.0,
          onTap: (PlacemarkMapObject self, Point point) {
            _onGasStationTap(station);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onServiceTap(AutoServiceModel service) {
    setState(() {
      _selectedService = service;
      _selectedGasStation = null;
    });
  }

  void _onGasStationTap(GasStationModel station) {
    setState(() {
      _selectedGasStation = station;
      _selectedService = null;
    });
  }

  Future<void> _toggleMarkers() async {
    _mapObjects.clear();
    await _addServiceMarkers();
    if (widget.gasStations != null) {
      await _addGasStationMarkers();
    }
    await _addUserLocationMarker();
  }

  void _buildRouteToService(AutoServiceModel service) async {
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

  void _buildRouteToGasStation(GasStationModel station) async {
    try {
      final userLocation = await _getUserLocation();

      if (userLocation != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'route'.tr()}: ${station.name}'),
              backgroundColor: Colors.green,
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

  Future<Point?> _getUserLocation() async {
    try {
      // Проверяем, включены ли службы геолокации
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Проверяем/запрашиваем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Получаем текущее местоположение с разумным таймаутом
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      return Point(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addUserLocationMarker() async {
    try {
      final location = await _getUserLocation();
      if (location == null) return;

      // Загружаем изображение из assets
      final ByteData imageData = await DefaultAssetBundle.of(
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
    } catch (e) {
      debugPrint('Error adding user location marker: $e');
    }
  }

  Future<void> _moveToUserLocation() async {
    if (_mapController == null) return;

    try {
      final location = await _getUserLocation();
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
                } else if (value == 'gas_stations') {
                  _showGasStations = !_showGasStations;
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
              if (widget.gasStations != null)
                CheckedPopupMenuItem<String>(
                  value: 'gas_stations',
                  checked: _showGasStations,
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('show_gas_stations'.tr()),
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return YandexMap(
                mapObjects: _mapObjects,
                onMapCreated: (YandexMapController controller) {
                  _mapController = controller;
                  _setMapTheme(themeProvider.isDarkMode);

                  // Начальную позицию не форсируем; при желании можно центрироваться на геопозиции пользователя
                },
                onCameraPositionChanged:
                    (
                      CameraPosition position,
                      CameraUpdateReason reason,
                      bool finished,
                    ) {},
              );
            },
          ),
          if (_selectedService != null)
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
                                  result['action'] == 'build_route') {
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
          if (_selectedGasStation != null)
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
                            Icons.local_gas_station,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedGasStation!.name,
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
                                _selectedGasStation = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedGasStation!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: _selectedGasStation!.fuelTypes
                            .map(
                              (fuel) => Chip(
                                label: Text(
                                  fuel,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _buildRouteToGasStation(_selectedGasStation!),
                        icon: const Icon(Icons.directions),
                        label: Text('route'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    if (_showServices &&
                        _showGasStations &&
                        widget.gasStations != null)
                      const SizedBox(height: 4),
                    if (_showGasStations && widget.gasStations != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_gas_station,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'gas_stations'.tr(),
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
