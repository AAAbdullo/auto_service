import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:auto_service/core/services/mapkit_routing_service.dart';

/// Кнопки выбора типа маршрута
class RouteTypeSelector extends StatelessWidget {
  final RouteType selectedType;
  final Function(RouteType) onTypeSelected;

  const RouteTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypeButton(
                type: RouteType.driving,
                icon: Icons.directions_car,
                label: 'Авто',
              ),
              const SizedBox(height: 12),
              _buildTypeButton(
                type: RouteType.walking,
                icon: Icons.directions_walk,
                label: 'Пешком',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required RouteType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedType == type;
    final color = _getTypeColor(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      height: 75,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTypeSelected(type),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(RouteType type) {
    switch (type) {
      case RouteType.driving:
        return const Color(0xFF2196F3);
      case RouteType.walking:
        return const Color(0xFF4CAF50);
    }
  }
}
