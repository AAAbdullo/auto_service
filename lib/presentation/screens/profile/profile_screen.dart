import 'dart:io';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/providers/profile_image_provider.dart';
import 'package:auto_service/presentation/providers/products_provider.dart';
import 'package:auto_service/presentation/screens/auth/login_screen.dart';
import 'package:auto_service/presentation/screens/profile/my_orders_screen.dart';
import 'package:auto_service/presentation/screens/shop/booked_parts_screen.dart';
import 'package:auto_service/presentation/screens/shop/add_product_screen.dart';
import 'package:auto_service/presentation/screens/shop/employee_bookings_screen.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/screens/profile/support_screen.dart';
import 'package:auto_service/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        final backgroundColor = theme.brightness == Brightness.dark
            ? Colors.black
            : const Color(0xFFF4F6FA);
        final cardColor = theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white;
        final iconBackground = theme.brightness == Brightness.dark
            ? Colors.blueGrey[700]
            : const Color(0xFFE3F2FD);
        final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
        final subtitleColor = theme.brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600];

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Шапка профиля
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Consumer<ProfileImageProvider>(
                        builder: (context, profileImageProvider, child) {
                          return GestureDetector(
                            onTap: () =>
                                _showImagePicker(context, profileImageProvider),
                            child: FutureBuilder<bool>(
                              future: _checkImageExists(
                                profileImageProvider.profileImagePath,
                              ),
                              builder: (context, snapshot) {
                                final imageExists = snapshot.data ?? false;
                                final imagePath =
                                    profileImageProvider.profileImagePath;

                                // 🎨 Более заметный аватар в темной теме
                                final isDark =
                                    theme.brightness == Brightness.dark;
                                final avatarBgColor = isDark
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      )
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      );
                                final avatarIconColor = isDark
                                    ? Colors.white
                                    : theme.colorScheme.primary;

                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: avatarBgColor,
                                  backgroundImage:
                                      (imageExists && imagePath != null)
                                      ? FileImage(File(imagePath))
                                      : null,
                                  child: (imageExists && imagePath != null)
                                      ? null
                                      : Icon(
                                          Icons.person,
                                          size: 50,
                                          color: avatarIconColor,
                                        ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            authProvider.currentUserPhone ?? '',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          // 🔹 Галочка для сотрудников автосервиса
                          if (authProvider.isServiceEmployee) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Скроллируемая часть меню
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 🔹 Пункт меню "Добавить товар" - только для сотрудников
                        if (authProvider.isServiceEmployee)
                          Consumer<ProductsProvider>(
                            builder: (context, productsProvider, _) {
                              final lowStockCount = productsProvider
                                  .getLowStockCount(
                                    authProvider.currentUserPhone ?? '',
                                  );
                              return _buildMenuItemWithBadge(
                                context,
                                icon: Icons.add_business,
                                title: 'add_product'.tr(),
                                subtitle: 'add_product_desc'.tr(),
                                badgeCount: lowStockCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddProductScreen(),
                                    ),
                                  );
                                },
                                cardColor: cardColor,
                                iconBackground: iconBackground,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              );
                            },
                          ),

                        // 🔹 "Мои заказы" - только для обычных пользователей
                        if (!authProvider.isServiceEmployee)
                          _buildMenuItem(
                            context,
                            icon: Icons.shopping_bag,
                            title: 'profile_my_orders'.tr(),
                            subtitle: 'orders_history'.tr(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyOrdersScreen(),
                                ),
                              );
                            },
                            cardColor: cardColor,
                            iconBackground: iconBackground,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),

                        // 🔹 "Забронированные детали" - разные экраны для сотрудников и обычных пользователей
                        if (authProvider.isServiceEmployee)
                          Consumer<BookingProvider>(
                            builder: (context, bookingProvider, _) {
                              final newBookingsCount = bookingProvider
                                  .getNewBookingsCount(
                                    authProvider.currentUserPhone ?? '',
                                  );
                              return _buildMenuItemWithBadge(
                                context,
                                icon: Icons.bookmark,
                                title: 'booked_parts'.tr(),
                                subtitle: 'employee_booked_parts_desc'.tr(),
                                badgeCount: newBookingsCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EmployeeBookingsScreen(),
                                    ),
                                  );
                                },
                                cardColor: cardColor,
                                iconBackground: iconBackground,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              );
                            },
                          )
                        else
                          _buildMenuItem(
                            context,
                            icon: Icons.bookmark,
                            title: 'booked_parts'.tr(),
                            subtitle: 'reserved_products'.tr(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BookedPartsScreen(),
                                ),
                              );
                            },
                            cardColor: cardColor,
                            iconBackground: iconBackground,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),

                        _buildMenuItem(
                          context,
                          icon: Icons.settings,
                          title: 'settings'.tr(),
                          subtitle: 'app_settings'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          iconBackground: iconBackground,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),

                        _buildMenuItem(
                          context,
                          icon: Icons.help_outline,
                          title: 'support'.tr(),
                          subtitle: 'faq_support'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupportScreen(),
                              ),
                            );
                          },
                          cardColor: cardColor,
                          iconBackground: iconBackground,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Кнопка выхода
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleLogout(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'logout'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
        );
      },
    );
  }

  Future<bool> _checkImageExists(String? imagePath) async {
    if (imagePath == null) return false;
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> _showImagePicker(
    BuildContext context,
    ProfileImageProvider profileImageProvider,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_profile_image'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'camera'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                      ImageSource.camera,
                      profileImageProvider,
                      context,
                    );
                  },
                ),
                _buildImageOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'gallery'.tr(),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                      ImageSource.gallery,
                      profileImageProvider,
                      context,
                    );
                  },
                ),
                if (profileImageProvider.profileImagePath != null)
                  _buildImageOption(
                    context,
                    icon: Icons.delete,
                    label: 'remove'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await profileImageProvider.removeProfileImage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('profile_image_removed'.tr()),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error removing profile image: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('error_removing_image'.tr()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    ProfileImageProvider profileImageProvider,
    BuildContext context,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Сохраняем изображение в постоянное хранилище
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = await File(image.path).copy('${directory.path}/$fileName');

        // Проверяем, что файл действительно создался
        if (await file.exists()) {
          await profileImageProvider.setProfileImage(file.path);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_image_updated'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to create image file');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_image'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logout_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color? cardColor,
    required Color? iconBackground,
    required Color? textColor,
    required Color? subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: subtitleColor),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItemWithBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int badgeCount,
    required VoidCallback onTap,
    required Color? cardColor,
    required Color? iconBackground,
    required Color? textColor,
    required Color? subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            if (badgeCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: subtitleColor),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey,
        ),
      ),
    );
  }
}
