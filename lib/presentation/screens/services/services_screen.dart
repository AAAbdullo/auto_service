import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/widgets/custom_search_bar.dart';
import 'package:auto_service/presentation/screens/services/service_detail_screen.dart';
import 'package:auto_service/presentation/screens/services/add_service_screen.dart';
import 'package:auto_service/presentation/screens/services/services_map_screen.dart';
import 'package:auto_service/main.dart';
import 'package:auto_service/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<AutoServiceModel> _services = [];
  List<AutoServiceModel> _allServices = [];
  bool _isLoading = false;

  // 🔹 Фильтры
  double? _minRating;
  final List<String> _selectedCategories = [];
  final List<String> _selectedBrands = [];
  RangeValues _priceRange = const RangeValues(0, 1000);
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _searchQuery = '';

  final List<double> _ratingFilters = [4.5, 4.0, 3.5, 3.0];

  // Категории и бренды теперь используют оригинальные ключи
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

  List<String> get _brands => [
    'Toyota',
    'BMW',
    'Mercedes',
    'Chevrolet',
    'Kia',
    'Hyundai',
    'Nissan',
    'Honda',
    'Ford',
    'Volkswagen',
    'Audi',
    'Lexus',
    'Mazda',
    'Subaru',
    'Mitsubishi',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Пытаемся получить текущее местоположение
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error getting location in ServicesScreen: $e');
      }

      // Используем Ташкент как дефолт, если геолокация недоступна
      final lat = position?.latitude ?? 41.2995;
      final lon = position?.longitude ?? 69.2401;

      debugPrint('📍 Loading services for location: $lat, $lon');

      // 🚀 ОПТИМИЗАЦИЯ: загружаем все сервисы параллельно для скорости
      final nearestFuture = AutoServicesRepository()
          .getNearestServices(
            lat: lat,
            lon: lon,
            radius: position != null ? 50000 : 500000, // 50км или 500км
          )
          .timeout(const Duration(seconds: 10))
          .catchError((_) => <AutoServiceModel>[]);

      final allServicesFuture = AutoServicesRepository()
          .getAllServices()
          .timeout(const Duration(seconds: 10))
          .catchError((_) => <AutoServiceModel>[]);

      final results = await Future.wait([nearestFuture, allServicesFuture]);
      List<AutoServiceModel> services = results[0];
      final allServices = results[1];

      // Если ближайшие не найдены, используем все
      if (services.isEmpty && allServices.isNotEmpty) {
        debugPrint('🔍 No nearest services found, using all services...');
        services = allServices;
      } else if (services.isEmpty && allServices.isEmpty) {
        debugPrint('⚠️ No services found at all');
      }

      if (!mounted) return;

      _allServices = services;
      _services = List.from(_allServices);

      if (_allServices.isNotEmpty) {
        _minPriceController.text = _priceRange.start.toInt().toString();
        _maxPriceController.text = _priceRange.end.toInt().toString();
      }

      debugPrint('✅ Loaded ${_services.length} services');

      // 🔄 Обновляем главный экран (карту) после загрузки сервисов
      final mainState = mainScreenKey.currentState;
      if (mainState != null) {
        debugPrint('🔄 Обновление главного экрана...');
        await mainState.refreshHomeServices();
      }
    } catch (e) {
      debugPrint('❌ Error loading services in ServicesScreen: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load services: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );

      _allServices = [];
      _services = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Ограничиваем высоту до 85% экрана для удобства
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Индикатор для сворачивания (drag handle)
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Заголовок
                      Text(
                        'filters'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Контент с прокруткой
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Категории
                              Text(
                                'service_type'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: _categories.map((category) {
                                  return ChoiceChip(
                                    label: Text(category.tr()),
                                    selected: _selectedCategories.contains(
                                      category,
                                    ),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedCategories.add(category);
                                        } else {
                                          _selectedCategories.remove(category);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),

                              // 🔹 Бренды
                              Text(
                                'brand'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: _brands.map((brand) {
                                  return ChoiceChip(
                                    label: Text(brand),
                                    selected: _selectedBrands.contains(brand),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          _selectedBrands.add(brand);
                                        } else {
                                          _selectedBrands.remove(brand);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),

                              // 🔹 Фильтр по цене
                              Text(
                                'price'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              RangeSlider(
                                values: _priceRange,
                                min: 0,
                                max: 1000,
                                divisions: 20,
                                labels: RangeLabels(
                                  '${_priceRange.start.toInt()}',
                                  '${_priceRange.end.toInt()}',
                                ),
                                onChanged: (values) {
                                  setModalState(() {
                                    _priceRange = values;
                                    _minPriceController.text = values.start
                                        .toInt()
                                        .toString();
                                    _maxPriceController.text = values.end
                                        .toInt()
                                        .toString();
                                  });
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'min_price'.tr(),
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        final v = double.tryParse(val) ?? 0;
                                        if (v < _priceRange.end) {
                                          setModalState(() {
                                            _priceRange = RangeValues(
                                              v,
                                              _priceRange.end,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'max_price'.tr(),
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        final v = double.tryParse(val) ?? 0;
                                        if (v > _priceRange.start) {
                                          setModalState(() {
                                            _priceRange = RangeValues(
                                              _priceRange.start,
                                              v,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // 🔹 Рейтинг
                              Text(
                                'rating'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: _ratingFilters.map((rating) {
                                  return ChoiceChip(
                                    label: Text('$rating+'),
                                    selected: _minRating == rating,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _minRating = selected ? rating : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 24),

                              // Кнопки действий
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _minRating = null;
                                        _selectedCategories.clear();
                                        _selectedBrands.clear();
                                        _priceRange = const RangeValues(
                                          0,
                                          1000,
                                        );
                                        _minPriceController.text = '0';
                                        _maxPriceController.text = '1000';
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
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _services = _allServices.where((service) {
        // Фильтр по рейтингу
        final matchesRating =
            _minRating == null || service.rating >= _minRating!;

        // Фильтр по услугам (категориям) - множественный выбор
        final matchesCategory =
            _selectedCategories.isEmpty ||
            _selectedCategories.any(
              (category) => service.services.any(
                (serviceItem) =>
                    serviceItem.toLowerCase().contains(
                      category.toLowerCase(),
                    ) ||
                    category.toLowerCase().contains(serviceItem.toLowerCase()),
              ),
            );

        // Фильтр по брендам - множественный выбор
        final matchesBrand =
            _selectedBrands.isEmpty ||
            _selectedBrands.any(
              (brand) =>
                  service.name.toLowerCase().contains(brand.toLowerCase()) ||
                  service.description.toLowerCase().contains(
                    brand.toLowerCase(),
                  ),
            );

        // Фильтр по цене (используем рейтинг как заглушку)
        final matchesPrice =
            service.rating * 100 >= _priceRange.start &&
            service.rating * 100 <= _priceRange.end;

        // Поиск по названию, описанию и услугам
        final matchesSearch =
            _searchQuery.isEmpty ||
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            service.services.any(
              (serviceItem) => serviceItem.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            );

        return matchesRating &&
            matchesCategory &&
            matchesBrand &&
            matchesPrice &&
            matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool filtersApplied =
        _minRating != null ||
        _selectedCategories.isNotEmpty ||
        _selectedBrands.isNotEmpty ||
        _searchQuery.isNotEmpty;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: CustomSearchBar(
                        hintText: 'search_hint'.tr(),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.map, color: theme.colorScheme.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ServicesMapScreen(services: _services),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: _openFilters,
                    ),
                  ),
                ],
              ),
            ),
            if (filtersApplied)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  "${'applied_filters'.tr()}: "
                  "${_selectedCategories.isNotEmpty ? _selectedCategories.map((c) => c.tr()).join(', ') : ''} "
                  "${_selectedBrands.isNotEmpty ? ', ${_selectedBrands.join(', ')}' : ''} "
                  "${_minRating != null ? ', ⭐ ${_minRating!}+' : ''} "
                  "${_searchQuery.isNotEmpty ? ', "$_searchQuery"' : ''}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadServices,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text('no_services_found'.tr()),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadServices,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final s = _services[index];

                          // Get image URL from images array or imageUrl
                          String? imageUrl;
                          if (s.images.isNotEmpty) {
                            // Используем новый метод для получения полного URL
                            imageUrl = s.images.first.getFullImageUrl();
                          } else if (s.imageUrl != null &&
                              s.imageUrl!.isNotEmpty) {
                            // Fallback на старое поле imageUrl
                            final baseUrl = ApiConfig.baseUrl;
                            if (s.imageUrl!.startsWith('http')) {
                              imageUrl = s.imageUrl;
                            } else if (s.imageUrl!.startsWith('/')) {
                              imageUrl = '$baseUrl${s.imageUrl}';
                            } else {
                              imageUrl = '$baseUrl/${s.imageUrl}';
                            }
                          }

                          return RepaintBoundary(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ServiceDetailScreen(service: s),
                                  ),
                                );

                                // Проверяем, нужно ли строить маршрут
                                if (result != null &&
                                    result['buildRoute'] == true) {
                                  if (!mounted) return;

                                  debugPrint(
                                    '🔹 Результат от ServiceDetailScreen: $result',
                                  );
                                  debugPrint(
                                    '🔹 Используем GlobalKey для доступа к MainScreenState',
                                  );

                                  // Используем глобальный ключ для доступа к MainScreen
                                  final mainState = mainScreenKey.currentState;

                                  if (mainState != null) {
                                    debugPrint(
                                      '✅ MainScreenState найден через GlobalKey!',
                                    );
                                    // Переходим на главную вкладку (карта)
                                    mainState.buildRouteFromService(
                                      result['latitude'],
                                      result['longitude'],
                                    );
                                  }
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Service Image or Icon
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 80,
                                          height: 80,
                                          child:
                                              imageUrl != null &&
                                                  imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) {
                                                    return Container(
                                                      color: theme
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      child: Icon(
                                                        Icons.car_repair,
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder:
                                                      (
                                                        _,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Container(
                                                          color: theme
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 30,
                                                              height: 30,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                )
                                              : Container(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.car_repair,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    size: 40,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Service Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              s.description,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  s.rating.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (s.reviewCount != null)
                                                  Text(
                                                    '(${s.reviewCount})',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.grey[500]
                                                          : Colors.grey[500],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_service_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServiceScreen()),
          );
          // 🎯 После создания сервиса - обновляем список и сразу показываем карту
          if (result == true) {
            if (!mounted) return;
            setState(() => _isLoading = true);
            try {
              await _loadServices();
              if (!mounted) return;
              // Сразу переходим на карту с обновленным списком и новым сервисом
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicesMapScreen(services: _services),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to map: $e');
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          }
        },
        tooltip: 'Add Service',
        child: const Icon(Icons.add),
      ),
    );
  }
}
