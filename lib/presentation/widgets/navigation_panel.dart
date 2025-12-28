import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_service/core/services/navigation_service.dart';

/// Панель навигации (отображается внизу экрана при активной навигации)
class NavigationPanel extends StatelessWidget {
  final NavigationState navigationState;
  final VoidCallback onStop;
  final bool ttsEnabled;
  final VoidCallback onTTSToggle;

  const NavigationPanel({
    super.key,
    required this.navigationState,
    required this.onStop,
    required this.ttsEnabled,
    required this.onTTSToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Метрики навигации
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Расстояние
                  _buildMetric(
                    icon: Icons.straighten,
                    label: 'distance'.tr(),
                    value: navigationState.formattedDistance,
                    color: Colors.blue,
                  ),

                  // Время
                  _buildMetric(
                    icon: Icons.access_time,
                    label: 'time'.tr(),
                    value: navigationState.formattedTime,
                    color: Colors.orange,
                  ),

                  // Скорость
                  _buildMetric(
                    icon: Icons.speed,
                    label: 'speed'.tr(),
                    value: navigationState.formattedSpeed,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Кнопки управления
              Row(
                children: [
                  // Кнопка TTS
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTTSToggle,
                      icon: Icon(
                        ttsEnabled ? Icons.volume_up : Icons.volume_off,
                        size: 20,
                      ),
                      label: Text(
                        ttsEnabled ? 'voice_on'.tr() : 'voice_off'.tr(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: ttsEnabled ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Кнопка остановки
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onStop,
                      icon: const Icon(Icons.stop, size: 20),
                      label: Text(
                        'stop_navigation'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
<<<<<<< HEAD
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        );
      },
=======
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    );
  }
}
