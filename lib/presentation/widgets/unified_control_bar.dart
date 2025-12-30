import 'package:flutter/material.dart';

/// Unified control bar with Search, Nearest, and Filter buttons
class UnifiedControlBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNearestTap;
  final VoidCallback onFilterTap;
  final bool isNearestMode;
  final bool hasActiveFilters;
  final String? nearestModeText;

  const UnifiedControlBar({
    super.key,
    required this.onSearchTap,
    required this.onNearestTap,
    required this.onFilterTap,
    this.isNearestMode = false,
    this.hasActiveFilters = false,
    this.nearestModeText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Search Button
              Expanded(
                child: _ControlButton(
                  icon: Icons.search_rounded,
                  label: 'Поиск',
                  onTap: onSearchTap,
                  isActive: false,
                  borderColor: borderColor,
                  isDark: isDark,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),

              // Nearest Button
              Expanded(
                child: _ControlButton(
                  icon: Icons.near_me_rounded,
                  label: 'Ближайшие',
                  onTap: onNearestTap,
                  isActive: isNearestMode,
                  borderColor: borderColor,
                  isDark: isDark,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),

              // Filter Button
              Expanded(
                child: _ControlButton(
                  icon: Icons.tune_rounded,
                  label: 'Фильтры',
                  onTap: onFilterTap,
                  isActive: hasActiveFilters,
                  borderColor: borderColor,
                  isDark: isDark,
                  theme: theme,
                  showBadge: hasActiveFilters,
                ),
              ),
            ],
          ),
        ),

        // Nearest mode indicator
        if (isNearestMode && nearestModeText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  nearestModeText!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color borderColor;
  final bool isDark;
  final ThemeData theme;
  final bool showBadge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    required this.borderColor,
    required this.isDark,
    required this.theme,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : (isDark ? Colors.grey[900] : Colors.grey[100]);

    final iconColor = isActive
        ? theme.colorScheme.primary
        : (isDark ? Colors.grey[400] : Colors.grey[700]);

    final textColor = isActive
        ? theme.colorScheme.primary
        : (isDark ? Colors.grey[400] : Colors.grey[700]);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : borderColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              // Badge indicator
              if (showBadge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: backgroundColor!, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
