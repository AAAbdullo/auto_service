import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_service/core/constants/route_types.dart';

class RouteTypeSelector extends StatelessWidget {
  final List<RouteInfo> routes;
  final RouteInfo? selectedRoute;
  final Function(RouteInfo) onRouteSelected;
  final VoidCallback? onGoPressed;
  final VoidCallback? onClosePressed;

  const RouteTypeSelector({
    super.key,
    required this.routes,
    this.selectedRoute,
    required this.onRouteSelected,
    this.onGoPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 20,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor.withValues(alpha: 0.98)
            : Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка для визуального указания на bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Заголовок
          Row(
            children: [
              Icon(
                Icons.route,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'travel_mode'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (onClosePressed != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClosePressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Типы маршрутов
          Row(
            children: routes.map((route) {
              final isSelected = selectedRoute?.type == route.type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _RouteTypeCard(
                    route: route,
                    isSelected: isSelected,
                    onTap: () => onRouteSelected(route),
                  ),
                ),
              );
            }).toList(),
          ),

          // Информация о выбранном маршруте
          if (selectedRoute != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selectedRoute!.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedRoute!.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(
                        icon: Icons.straighten,
                        label: 'distance'.tr(),
                        value: selectedRoute!.formattedDistance,
                        color: selectedRoute!.color,
                      ),
                      _InfoItem(
                        icon: Icons.access_time,
                        label: 'time'.tr(),
                        value: selectedRoute!.formattedDuration,
                        color: selectedRoute!.color,
                      ),
                    ],
                  ),
                  // Убрали отображение transitInfo (комментарии о сервисе)
                ],
              ),
            ),
          ],

          // Кнопка "Поехали"
          if (selectedRoute != null && onGoPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onGoPressed,
                icon: const Icon(Icons.navigation, size: 18),
                label: Text(
                  'go_button'.tr(),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRoute!.color,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: selectedRoute!.color.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteTypeCard extends StatelessWidget {
  final RouteInfo route;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteTypeCard({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? route.color.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? route.color
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              route.icon,
              size: 28,
              color: isSelected ? route.color : Colors.grey[600],
            ),
            const SizedBox(height: 3),
            Text(
              route.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? route.color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              route.formattedDuration,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? route.color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
