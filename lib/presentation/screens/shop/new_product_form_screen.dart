import 'dart:io';
import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/presentation/providers/products_provider.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class NewProductFormScreen extends StatefulWidget {
  const NewProductFormScreen({super.key});

  @override
  State<NewProductFormScreen> createState() => _NewProductFormScreenState();
}

class _NewProductFormScreenState extends State<NewProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _brandController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'Remont';
  File? _selectedImage;
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Если это камера, запрашиваем разрешение камеры
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;

        if (cameraStatus.isDenied) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            if (result.isPermanentlyDenied && mounted) {
              _showPermissionDialog(true);
            }
            return;
          }
        } else if (cameraStatus.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDialog(true);
          }
          return;
        } else if (!cameraStatus.isGranted) {
          return;
        }
      } else {
        // Для галереи используем правильные разрешения
        if (Platform.isIOS) {
          // iOS: используем photos
          final photosStatus = await Permission.photos.status;

          if (photosStatus.isDenied) {
            final result = await Permission.photos.request();
            if (!result.isGranted) {
              if (result.isPermanentlyDenied && mounted) {
                _showPermissionDialog(false);
              }
              return;
            }
          } else if (photosStatus.isPermanentlyDenied) {
            if (mounted) {
              _showPermissionDialog(false);
            }
            return;
          } else if (!photosStatus.isGranted) {
            return;
          }
        } else {
          // Android: используем photos для API 33+ и storage для более старых версий
          // Сначала проверяем photos (для Android 13+)
          final photosStatus = await Permission.photos.status;
          bool permissionGranted = false;

          if (photosStatus.isGranted) {
            permissionGranted = true;
          } else if (photosStatus.isDenied) {
            final photosResult = await Permission.photos.request();
            if (photosResult.isGranted) {
              permissionGranted = true;
            }
          }

          // Если photos не доступно, пытаемся storage (для Android 10-12)
          if (!permissionGranted) {
            final storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) {
              permissionGranted = true;
            } else if (storageStatus.isDenied) {
              final storageResult = await Permission.storage.request();
              if (storageResult.isGranted) {
                permissionGranted = true;
              } else if (storageResult.isPermanentlyDenied && mounted) {
                _showPermissionDialog(false);
                return;
              }
            } else if (storageStatus.isPermanentlyDenied && mounted) {
              _showPermissionDialog(false);
              return;
            }
          }

          // Если photos постоянно отклонено, показываем диалог
          if (photosStatus.isPermanentlyDenied && mounted) {
            _showPermissionDialog(false);
            return;
          }

          if (!permissionGranted) {
            return;
          }
        }
      }

      // Разрешение получено, выбираем изображение
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = null; // Очищаем URL если был выбран файл
        });
      }
    } catch (e) {
      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(bool isCamera) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('permission_required'.tr()),
        content: Text(
          isCamera
              ? 'camera_permission_required'.tr()
              : 'gallery_permission_required'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_image_source'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text('from_gallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: Text('from_camera'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final productsProvider = context.read<ProductsProvider>();
    final ownerPhone = authProvider.currentUserPhone ?? '';

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final brand = _brandController.text.trim();

    // Для демо используем путь к файлу как URL
    // В реальном приложении нужно загрузить изображение на сервер
    String? finalImageUrl;
    if (_selectedImage != null) {
      finalImageUrl = _selectedImage!.path;
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      finalImageUrl = _imageUrl;
    }

    final newProduct = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      price: price,
      imageUrl: finalImageUrl,
      rating: 4.5,
      reviewCount: 0,
      category: _selectedCategory,
      brand: brand.isEmpty ? null : brand,
      inStock: true,
      quantity: quantity,
      ownerPhone: ownerPhone,
    );

    await productsProvider.addProduct(newProduct);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[100],
      appBar: AppBar(
        title: Text('add_new_product'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Выбор изображения
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'product_image'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'select_image_source'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Название товара
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '${'product_name'.tr()} *',
                    hintText: 'product_name_hint'.tr(),
                    prefixIcon: const Icon(Icons.shopping_bag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'product_name_required'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Описание
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '${'product_description_label'.tr()} *',
                    hintText: 'product_description_hint'.tr(),
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'product_description_required'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Цена и количество
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '${'product_price'.tr()} *',
                          hintText: 'product_price_hint'.tr(),
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'product_price_required'.tr();
                          }
                          if (double.tryParse(value) == null) {
                            return 'invalid_format'.tr();
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '${'product_quantity'.tr()} *',
                          hintText: 'product_quantity_hint'.tr(),
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'product_quantity_required'.tr();
                          }
                          if (int.tryParse(value) == null) {
                            return 'invalid_format'.tr();
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Категория
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.white,
                  ),
                  items: ['Remont', 'Dvigatel', 'Kuzov', 'Elektronika']
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            'category_${category.toLowerCase()}'.tr(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Бренд
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'brand_label'.tr(),
                    hintText: 'brand_hint'.tr(),
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save),
                    label: Text(
                      'add_product'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }
}
