import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

/// Экран выбора локации на карте
class LocationPickerScreen extends StatefulWidget {
  final Point? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  YandexMapController? _mapController;
  Point _selectedLocation = const Point(latitude: 41.2995, longitude: 69.2401);
  String _selectedAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
    }
  }

  /// Получить текущую локацию пользователя
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('location_permission_denied'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = Point(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });
      }

      // Переместить камеру к текущей локации
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation, zoom: 15.0),
        ),
      );
    } catch (e) {
      debugPrint('Ошибка получения локации: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_getting_location'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Подтвердить выбранную локацию
  void _confirmLocation() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('select_location'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: 'confirm'.tr(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта
          YandexMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _selectedLocation, zoom: 15.0),
                ),
              );
            },
            onCameraPositionChanged: (cameraPosition, reason, finished) {
              // Обновляем выбранную локацию при перемещении карты
              if (finished) {
                setState(() {
                  _selectedLocation = cameraPosition.target;
                });
              }
            },
            mapObjects: [],
          ),

          // Центральный маркер (фиксированный в центре экрана)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_pin, size: 48, color: Colors.red),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Кнопка "Моя локация"
          Positioned(
            bottom: 170,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: _getCurrentLocation,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.my_location),
            ),
          ),

          // Информационная панель внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'selected_location'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress.isEmpty
                          ? '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}'
                          : _selectedAddress,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _confirmLocation,
                        icon: const Icon(Icons.check),
                        label: Text(
                          'confirm_location'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
