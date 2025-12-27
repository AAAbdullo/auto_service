import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:auto_service/presentation/screens/common/location_picker_screen.dart';
import 'dart:io';
import 'dart:async';

class AddServiceScreen extends StatefulWidget {
  final AutoServiceModel? serviceToEdit;

  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceInputController = TextEditingController();
  final _telegramController = TextEditingController();

  // State
  bool _isLoading = false;
  double? _selectedLat;
  double? _selectedLon;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Mon-Fri default
  final List<String> _services = []; // List of services provided
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Yandex Map
  late YandexMapController _mapController;
  final List<MapObject> _mapObjects = [];
  final bool _mapInitialized = false;

  List<ServiceCategory> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.serviceToEdit != null) {
      // Defer population until categories are loaded or just populate fields that don't depend on them
      // But _selectedCategoryId logic depends on categories being present?
      // Actually we can set the ID even if categories aren't loaded yet, dropdown will match when loaded.
      _populateForm();
    } else {
      _determinePosition();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await AutoServicesRepository().getServiceCategories();
      if (mounted) {
        setState(() {
          // If API returns empty, use fallback categories
          if (categories.isEmpty) {
            _categories = [
              ServiceCategory(id: 1, name: 'Диагностика', slug: 'diagnostics'),
              ServiceCategory(
                id: 2,
                name: 'Ремонт двигателя',
                slug: 'engine-repair',
              ),
              ServiceCategory(id: 3, name: 'Замена масла', slug: 'oil-change'),
              ServiceCategory(id: 4, name: 'Шиномонтаж', slug: 'tire-service'),
              ServiceCategory(
                id: 5,
                name: 'Ремонт тормозов',
                slug: 'brake-repair',
              ),
            ];
          } else {
            _categories = categories;
          }
          // Set default if adding new service and we have categories
          if (widget.serviceToEdit == null &&
              _categories.isNotEmpty &&
              _selectedCategoryId == null) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      // On error, use fallback categories
      if (mounted) {
        setState(() {
          _categories = [
            ServiceCategory(id: 1, name: 'Диагностика', slug: 'diagnostics'),
            ServiceCategory(
              id: 2,
              name: 'Ремонт двигателя',
              slug: 'engine-repair',
            ),
            ServiceCategory(id: 3, name: 'Замена масла', slug: 'oil-change'),
            ServiceCategory(id: 4, name: 'Шиномонтаж', slug: 'tire-service'),
            ServiceCategory(
              id: 5,
              name: 'Ремонт тормозов',
              slug: 'brake-repair',
            ),
          ];
          if (widget.serviceToEdit == null && _selectedCategoryId == null) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    }
  }

  void _populateForm() {
    final service = widget.serviceToEdit!;
    _nameController.text = service.name;
    _descController.text = service.description;
    _addressController.text = service.address ?? '';
    _phoneController.text = service.phone ?? '';
    _telegramController.text = service.telegram ?? '';
    _selectedLat = service.latitude;
    _selectedLon = service.longitude;

    // Attempt to match category.
    // If service model services list contains strings that match category IDs?
    // Or if we need a field in AutoServiceModel for category ID?
    // Current AutoServiceModel doesn't seem to have a single 'categoryId' field exposed in constructor or props well?
    // The previous error logs showed 'category' field being sent.
    // Use a default for now if we can't find it.
    // Ideally AutoServiceModel should have `categoryId`.
    // It has `List<String> services`. API might return category names there?
    // Or maybe we just default to null and user selects.
  }

  Future<void> _determinePosition() async {
    // Basic geolocation logic to get initial center
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLat = position.latitude;
      _selectedLon = position.longitude;
      _updateMapMarker();
    });

    if (_mapInitialized) {
      _mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: _selectedLat!, longitude: _selectedLon!),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _updateMapMarker() {
    if (_selectedLat == null || _selectedLon == null) return;

    setState(() {
      _mapObjects.clear();
      _mapObjects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('selection'),
          point: Point(latitude: _selectedLat!, longitude: _selectedLon!),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(
                'assets/images/marker.png',
              ), // Fallback if no marker asset
              scale: 1,
            ),
          ),
          opacity: 1,
        ),
      );
    });
  }

  Widget _buildDayChip(int day, String labelKey) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedDays.contains(day);
    final primaryColor = theme.colorScheme.primary;

    return FilterChip(
      label: Text(
        labelKey.tr(),
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLat == null || _selectedLon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('please_select_location'.tr())));
      return;
    }

    // Note: Category is now handled automatically in the background
    if (_selectedCategoryId == null) {
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No categories loaded')),
        );
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.getAccessToken();

    if (token == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final serviceData = {
      'name': _nameController.text,
      'description': _descController.text,
      'address': _addressController.text,
      'phone_number': _phoneController.text,
      'telegram': _telegramController.text.isNotEmpty
          ? _telegramController.text
          : null,
      'start_time':
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time':
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
      'working_days': _selectedDays.toList(),
      'category': _selectedCategoryId,
      'lat': _selectedLat,
      'lon': _selectedLon,
      'latitude': _selectedLat,
      'longitude': _selectedLon,
      'is_active': true,
    };
    // Note: If backend expects single Int for OneToMany, safely try [id] or id.
    // The error `{"category":["Invalid pk \"1\" ..."]}` suggests it validated "1" successfully as a PK type but failed existence.
    // Sending it as a list `[_selectedCategoryId]` might be safer for ManyToMany.
    // Let's try sending as list first as that's common for categories.

    bool success = false;
    int? serviceId;

    if (widget.serviceToEdit != null) {
      success = await AutoServicesRepository().updateService(
        id: int.parse(widget.serviceToEdit!.id),
        data: serviceData,
      );
      serviceId = int.parse(widget.serviceToEdit!.id);
    } else {
      final result = await AutoServicesRepository().createService(
        serviceData: serviceData,
      );
      success = result != null;
      serviceId = result != null ? int.tryParse(result.id) : null;
    }

    // Загружаем изображение если оно выбрано
    if (success && _selectedImage != null && serviceId != null) {
      debugPrint('📸 Попытка загрузки изображения...');
      debugPrint('   Service ID: $serviceId');
      debugPrint('   Image Path: ${_selectedImage!.path}');

      final imageSuccess = await AutoServicesRepository().addServiceImage(
        serviceId: serviceId,
        imagePath: _selectedImage!.path,
      );

      if (imageSuccess) {
        debugPrint('✅ Изображение успешно загружено из AddServiceScreen');
      } else {
        debugPrint('⚠️ Ошибка загрузки изображения в AddServiceScreen');
      }
    } else {
      debugPrint('⚠️ Пропуск загрузки изображения:');
      debugPrint('   Success: $success');
      debugPrint('   Image selected: ${_selectedImage != null}');
      debugPrint('   Service ID: $serviceId');
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.serviceToEdit != null
                ? 'Service updated!'
                : 'Service created successfully!',
          ),
        ),
      );
      Navigator.pop(context, true); // Return true to indicate refresh needed
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving service')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Сжимаем для уменьшения размера
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Ошибка выбора изображения: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error_picking_image'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serviceToEdit != null
              ? 'edit_auto_service'.tr()
              : 'add_auto_service'.tr(),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: surfaceColor,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 📋 Basic Info Section
            _buildSection(
              context,
              title: 'basic_information'.tr(),
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'service_name'.tr(),
                  icon: Icons.business_outlined,
                  validator: (v) => v?.isEmpty == true ? 'required'.tr() : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descController,
                  label: 'description'.tr(),
                  icon: Icons.notes,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'phone_number'.tr(),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'required'.tr() : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'address'.tr(),
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _telegramController,
                  label: 'telegram'.tr(),
                  icon: Icons.send_outlined,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📷 Image Section
            _buildSection(
              context,
              title: 'service_image'.tr(),
              icon: Icons.image,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: surfaceColor,
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: primaryColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'tap_to_add_image'.tr(),
                                style: TextStyle(
                                  color: primaryColor.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      'remove_image'.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // 🛠️ Services Input Section
            _buildSection(
              context,
              title: 'additional_services'.tr(),
              icon: Icons.miscellaneous_services,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serviceInputController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'enter_service_name'.tr(),
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (_serviceInputController.text.trim().isNotEmpty) {
                            setState(() {
                              _services.add(
                                _serviceInputController.text.trim(),
                              );
                              _serviceInputController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'add'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_services.isNotEmpty)
                  ...List.generate(_services.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _services[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _services.removeAt(index);
                              });
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 20),

            // 📅 Working Days Section
            _buildSection(
              context,
              title: 'working_days'.tr(),
              icon: Icons.calendar_today,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDayChip(1, 'monday'),
                    _buildDayChip(2, 'tuesday'),
                    _buildDayChip(3, 'wednesday'),
                    _buildDayChip(4, 'thursday'),
                    _buildDayChip(5, 'friday'),
                    _buildDayChip(6, 'saturday'),
                    _buildDayChip(7, 'sunday'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ⏰ Working Hours Section
            _buildSection(
              context,
              title: 'working_hours'.tr(),
              icon: Icons.access_time,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (t != null) setState(() => _startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'start_time'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (t != null) setState(() => _endTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'end_time'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📍 Location Section
            _buildSection(
              context,
              title: 'location'.tr(),
              icon: Icons.location_on,
              children: [
                // Location Picker Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerScreen(
                              initialLocation:
                                  _selectedLat != null && _selectedLon != null
                                  ? Point(
                                      latitude: _selectedLat!,
                                      longitude: _selectedLon!,
                                    )
                                  : null,
                              initialAddress: _addressController.text,
                            ),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _selectedLat = result['location'].latitude;
                            _selectedLon = result['location'].longitude;
                            if (result['address'] != null &&
                                result['address'].toString().isNotEmpty) {
                              _addressController.text = result['address'];
                            }
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('location_selected'.tr()),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.map,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedLat != null
                                  ? 'change_location'.tr()
                                  : 'select_on_map'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Location Preview
                if (_selectedLat != null && _selectedLon != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'selected_location'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLon!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (_addressController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _addressController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Mini Map Preview
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: YandexMap(
                        onMapCreated: (controller) {
                          controller.moveCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: Point(
                                  latitude: _selectedLat!,
                                  longitude: _selectedLon!,
                                ),
                                zoom: 15,
                              ),
                            ),
                          );
                        },
                        mapObjects: [
                          PlacemarkMapObject(
                            mapId: const MapObjectId('preview'),
                            point: Point(
                              latitude: _selectedLat!,
                              longitude: _selectedLon!,
                            ),
                            opacity: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.serviceToEdit != null
                            ? 'save_service'.tr()
                            : 'save_service'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    return Card(
      elevation: isDark ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: isDark,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white24
                : primaryColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
