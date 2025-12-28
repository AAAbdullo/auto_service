import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/widgets/custom_search_bar.dart';
import 'package:auto_service/presentation/screens/services/service_detail_screen.dart';
import 'package:auto_service/presentation/screens/services/add_service_screen.dart';
import 'package:auto_service/main.dart';
import 'package:auto_service/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => ServicesScreenState();
}

class ServicesScreenState extends State<ServicesScreen> {
  List<AutoServiceModel> _services = [];
  List<AutoServiceModel> _allServices = [];
  bool _isLoading = false;

  // 🔹 Фильтры
  double? _minRating;
  final List<String> _selectedCategories = [];
  String _searchQuery = '';

  final List<double> _ratingFilters = [4.5, 4.0, 3.5, 3.0];

  // Категории
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

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Сначала загружаем "Все сервисы" - это самый надежный метод
      debugPrint('📍 Loading all services first...');
      final allServices = await AutoServicesRepository().getAllServices();
      debugPrint('✅ Loaded ${allServices.length} services (base list)');

      // 2. Параллельно (или после) пытаемся получить локацию для сортировки
      List<AutoServiceModel> sortedServices = allServices;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          // Пробуем быстро получить кэш
          Position? position = await Geolocator.getLastKnownPosition();
          // Если нет кэша, пробуем GPS но недолго
          position ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 4),
          );

          debugPrint(
            '📍 Got location: ${position.latitude}, ${position.longitude}',
          );
          // Если локация есть, пробуем получить "ближайшие" с API (если сервер умеет сортировать)
          try {
            final nearest = await AutoServicesRepository().getNearestServices(
              lat: position.latitude,
              lon: position.longitude,
              radius: 50000, // 50 km
            );
            if (nearest.isNotEmpty) {
              sortedServices = nearest;
              debugPrint('✅ Switched to nearest services (${nearest.length})');
            }
          } catch (e) {
            debugPrint(
              '⚠️ Nearest API failed, keeping all services list. Error: $e',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Location check failed: $e');
      }

      if (!mounted) return;

      _allServices = sortedServices;
      _services = List.from(_allServices);

      // 🔄 Обновляем главный экран
      final mainState = mainScreenKey.currentState;
      if (mainState != null) {
        mainState.refreshHomeServices();
      }
    } catch (e) {
      debugPrint('❌ Critical error loading services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load services: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _allServices = [];
      _services = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> refresh() async {
    await _loadServices();
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
            // Use the hardcoded categories
            final categoriesToShow = _categories;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
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
                      Text(
                        'filters'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Услуги (Categories only)
                              Text(
                                'services_title'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: categoriesToShow.map((category) {
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

                              // 🔹 Рейтинг
                              Text(
                                'rating'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
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

        // Фильтр по категориям
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

        // Поиск по названию и описанию
        final matchesSearch =
            _searchQuery.isEmpty ||
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            // Также ищем в дополнительных услугах
            (service.extraServices?.any(
                  (es) => es.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                ) ??
                false);

        return matchesRating && matchesCategory && matchesSearch;
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
          // 🎯 После создания сервиса - обновляем список
          if (result == true) {
            if (!mounted) return;
            await _loadServices();
          }
        },
        tooltip: 'Add Service',
        child: const Icon(Icons.add),
      ),
    );
  }
}
