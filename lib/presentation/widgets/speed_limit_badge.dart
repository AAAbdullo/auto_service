import 'package:flutter/material.dart';

class SpeedLimitBadge extends StatelessWidget {
  final int? speedLimitKmh;
  final bool highlight;

  const SpeedLimitBadge({
    super.key,
    required this.speedLimitKmh,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final String text = speedLimitKmh == null
        ? '--'
        : speedLimitKmh!.toString();
    final Color border = highlight ? Colors.red : Colors.black87;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: border, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: text.length >= 3 ? 14 : 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
