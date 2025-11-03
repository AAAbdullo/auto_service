import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';

class LocationPermissionDialog extends StatelessWidget {
  final bool isServiceDisabled;
  final bool isPermanentlyDenied;

  const LocationPermissionDialog({
    super.key,
    this.isServiceDisabled = false,
    this.isPermanentlyDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Заголовок
            Text(
              isServiceDisabled
                  ? 'location_service_disabled_title'.tr()
                  : isPermanentlyDenied
                  ? 'location_permanently_denied_title'.tr()
                  : 'location_permission_title'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Описание
            Text(
              isServiceDisabled
                  ? 'location_service_disabled_message'.tr()
                  : isPermanentlyDenied
                  ? 'location_permanently_denied_message'.tr()
                  : 'location_permission_message'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Список требований
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'location_requirements_title'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementItem(
                    context,
                    Icons.location_searching,
                    'location_requirement_1'.tr(),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem(
                    context,
                    Icons.map,
                    'location_requirement_2'.tr(),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem(
                    context,
                    Icons.speed,
                    'location_requirement_3'.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: isPermanentlyDenied ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: () => _handleLocationAction(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isServiceDisabled || isPermanentlyDenied
                          ? 'open_settings'.tr()
                          : 'enable'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Обработка действий с геолокацией
  Future<void> _handleLocationAction(BuildContext context) async {
    try {
      if (isServiceDisabled) {
        // Попытка включить GPS автоматически
        await Geolocator.openLocationSettings();
      } else if (isPermanentlyDenied) {
        // Открыть настройки приложения для разрешений
        await AppSettings.openAppSettings();
      } else {
        // Запрос разрешения на геолокацию
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.of(context).pop(false);
          return;
        }
      }
      
      // Закрыть диалог с успешным результатом
      Navigator.of(context).pop(true);
    } catch (e) {
      // В случае ошибки открыть настройки системы
      await AppSettings.openAppSettings();
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildRequirementItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Показать диалог с запросом включения GPS
  static Future<bool?> showLocationServiceDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WillPopScope(
        onWillPop: () async => true,
        child: const LocationPermissionDialog(isServiceDisabled: true),
      ),
    );
  }

  /// Показать диалог с запросом разрешения на геолокацию
  static Future<bool?> showLocationPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WillPopScope(
        onWillPop: () async => true,
        child: const LocationPermissionDialog(),
      ),
    );
  }

  /// Показать диалог при постоянном отказе от разрешения
  static Future<bool?> showPermanentlyDeniedDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WillPopScope(
        onWillPop: () async => true,
        child: const LocationPermissionDialog(isPermanentlyDenied: true),
      ),
    );
  }
}
