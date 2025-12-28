import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/providers/products_provider.dart';
import 'package:auto_service/presentation/screens/auth/login_screen.dart';
import 'package:auto_service/presentation/screens/profile/my_orders_screen.dart';

import 'package:auto_service/presentation/screens/shop/add_product_screen.dart';
import 'package:auto_service/presentation/screens/shop/employee_bookings_screen.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/screens/profile/support_screen.dart';
import 'package:auto_service/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_service/core/config/api_config.dart';

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
        final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
        final subtitleColor = theme.brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600];

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // 👤 Profile Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showImagePicker(context, authProvider),
                        child: Builder(
                          builder: (context) {
                            final userProfile = authProvider.userProfile;
                            final imagePath =
                                userProfile?.image; // URL from API

                            final isDark = theme.brightness == Brightness.dark;
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

                            ImageProvider? imageProvider;
                            if (imagePath != null && imagePath.isNotEmpty) {
                              if (imagePath.startsWith('http')) {
                                imageProvider = NetworkImage(imagePath);
                              } else {
                                imageProvider = NetworkImage(
                                  '${ApiConfig.baseUrl}$imagePath',
                                );
                              }
                            }

                            return Stack(
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: avatarBgColor,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Icon(
                                          Icons.person,
                                          size: 55,
                                          color: avatarIconColor,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      authProvider.userProfile?.fullName ??
                                          authProvider.currentUserPhone ??
                                          'User',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (authProvider.userProfile?.isSuperuser ==
                                      true) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              if (authProvider.userProfile?.fullName != null)
                                Text(
                                  authProvider.currentUserPhone ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: theme.colorScheme.primary,
                            onPressed: () =>
                                _showEditProfileDialog(context, authProvider),
                          ),
                          // 🔹 Роль сотрудника больше не разделяется на backend,
                          // поэтому бейдж отключён, чтобы не вводить в заблуждение.
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 📋 Menu Items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        // 🛍️ Магазин: добавление товаров (только для админов)
                        if (authProvider.userProfile?.isSuperuser == true)
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
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              );
                            },
                          ),

                        // 📦 Мои заказы
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
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),

                        // 🔖 Бронирования (Для сотрудников/владельцев) - Backend
                        Consumer<BookingProvider>(
                          builder: (context, bookingProvider, _) {
                            // Мы можем показывать количество новых, если бы API поддерживал это
                            // Пока просто показываем кнопку
                            return _buildMenuItem(
                              context,
                              icon: Icons.bookmark,
                              title: 'employee_booked_parts_title'
                                  .tr(), // "Бронирования (Сотрудник)"
                              subtitle: 'employee_booked_parts_desc'
                                  .tr(), // "Входящие бронирования"
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
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            );
                          },
                        ),

                        // ⚙️ Settings
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
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),

                        // ❓ Support
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
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // 🚪 Logout Button
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

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final nameController = TextEditingController(
      text: authProvider.userProfile?.fullName ?? '',
    );
    final telegramController = TextEditingController(
      text: authProvider.userProfile?.telegram ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_profile'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'full_name'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telegramController,
              decoration: InputDecoration(
                labelText: 'telegram'.tr(),
                border: const OutlineInputBorder(),
                prefixText: '@',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newTelegram = telegramController.text.trim();

              if (newName.isNotEmpty) {
                Navigator.pop(context); // Close dialog

                final data = {'full_name': newName};
                if (newTelegram.isNotEmpty) {
                  data['telegram'] = newTelegram;
                } else {
                  // If user clears telegram, send null or empty string?
                  // API spec for Userx says telegram is string, nullable.
                  data['telegram'] =
                      ""; // Sending empty string to clear it if backend supports it
                }

                final success = await authProvider.updateProfile(data);

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('profile_updated'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('error_updating_profile'.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker(
    BuildContext context,
    AuthProvider authProvider,
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
                    await _pickImage(ImageSource.camera, authProvider, context);
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
                      authProvider,
                      context,
                    );
                  },
                ),
                // Only show delete if user has image
                if (authProvider.userProfile?.image != null)
                  _buildImageOption(
                    context,
                    icon: Icons.delete,
                    label: 'remove'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      // Currently API has clean upload, but not explicit delete?
                      // Usually uploading null or specific call.
                      // For now, allow upload.
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
    AuthProvider authProvider,
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
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('uploading_image'.tr())));
        }

        final success = await authProvider.uploadProfileImage(image.path);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_image_updated'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('error_updating_image'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
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
    required Color? textColor,
    required Color? subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
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
    required Color? textColor,
    required Color? subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
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
            fontSize: 15,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
      ),
    );
  }
}
