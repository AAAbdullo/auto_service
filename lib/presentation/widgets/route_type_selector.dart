import 'package:flutter/material.dart';
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeButton(
              type: RouteType.driving,
              icon: Icons.directions_car,
              label: 'Авто',
            ),
            const SizedBox(height: 8),
            _buildTypeButton(
              type: RouteType.walking,
              icon: Icons.directions_walk,
              label: 'Пешком',
            ),
          ],
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

    return Material(
      color: isSelected ? _getTypeColor(type) : Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onTypeSelected(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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
        return Colors.blue;
      case RouteType.walking:
        return Colors.green;
    }
  }
}
