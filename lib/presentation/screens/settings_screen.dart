import 'package:auto_service/presentation/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Слушаем язык напрямую через LanguageProvider (он обновляется мгновенно)
    final _ = context.watch<LanguageProvider>().locale;

    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 Раздел темы
            Text(
              'theme_section'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    _buildThemeTile(
                      context: context,
                      title: 'theme_system'.tr(),
                      subtitle: 'theme_system_desc'.tr(),
                      icon: Icons.brightness_auto,
                      value: AppThemeMode.system,
                      groupValue: themeProvider.appThemeMode,
                      onChanged: (mode) {
                        if (mode != null && context.mounted) {
                          themeProvider.setTheme(mode);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildThemeTile(
                      context: context,
                      title: 'theme_light'.tr(),
                      subtitle: 'theme_light_desc'.tr(),
                      icon: Icons.light_mode,
                      value: AppThemeMode.light,
                      groupValue: themeProvider.appThemeMode,
                      onChanged: (mode) {
                        if (mode != null && context.mounted) {
                          themeProvider.setTheme(mode);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildThemeTile(
                      context: context,
                      title: 'theme_dark'.tr(),
                      subtitle: 'theme_dark_desc'.tr(),
                      icon: Icons.dark_mode,
                      value: AppThemeMode.dark,
                      groupValue: themeProvider.appThemeMode,
                      onChanged: (mode) {
                        if (mode != null && context.mounted) {
                          themeProvider.setTheme(mode);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 🌐 Раздел языка
            Text(
              'language_section'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Column(
                  children: [
                    ListTile(
                      title: Text('language_section'.tr()),
                      subtitle: Text(
                        languageProvider.locale.languageCode == 'uz'
                            ? 'language_uz'.tr()
                            : 'language_ru'.tr(),
                      ),
                    ),
                    RadioListTile<String>(
                      title: Text('language_uz'.tr()),
                      value: 'uz',
                      groupValue: languageProvider.locale.languageCode,
                      onChanged: (value) {
                        if (value != null && context.mounted) {
                          languageProvider.setLanguage(context, value);
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('language_ru'.tr()),
                      value: 'ru',
                      groupValue: languageProvider.locale.languageCode,
                      onChanged: (value) {
                        if (value != null && context.mounted) {
                          languageProvider.setLanguage(context, value);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildThemeTile({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required AppThemeMode value,
  required AppThemeMode groupValue,
  required ValueChanged<AppThemeMode?> onChanged,
}) {
  final isSelected = value == groupValue;
  final theme = Theme.of(context);
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    ),
    child: RadioListTile<AppThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Text(subtitle),
      ),
      activeColor: theme.colorScheme.primary,
    ),
  );
}
