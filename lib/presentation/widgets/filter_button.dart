import 'package:flutter/material.dart';

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF0D47A1),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
