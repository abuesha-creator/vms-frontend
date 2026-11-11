import 'package:flutter/material.dart';

/// A high-contrast, accessible status badge that clearly highlights
/// vehicle operational states (ACTIVE, MAINTENANCE, INACTIVE).
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;
    final Color dot;
    final IconData icon;
    final String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = const Color(0xFFECFDF5); // Emerald 50
        border = const Color(0xFFA7F3D0); // Emerald 200
        text = const Color(0xFF065F46); // Emerald 800
        dot = const Color(0xFF059669); // Emerald 600
        icon = Icons.check_circle_rounded;
        label = 'Active';
        break;
      case 'MAINTENANCE':
        bg = const Color(0xFFFFFBEB); // Amber 50
        border = const Color(0xFFFDE68A); // Amber 200
        text = const Color(0xFF92400E); // Amber 800
        dot = const Color(0xFFD97706); // Amber 600
        icon = Icons.build_circle_rounded;
        label = 'Maintenance';
        break;
      case 'INACTIVE':
      default:
        bg = const Color(0xFFF8FAFC); // Slate 50
        border = const Color(0xFFCBD5E1); // Slate 300
        text = const Color(0xFF334155); // Slate 700
        dot = const Color(0xFF64748B); // Slate 500
        icon = Icons.pause_circle_rounded;
        label = status.isEmpty
            ? 'Inactive'
            : status[0].toUpperCase() + status.substring(1).toLowerCase();
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 9,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 8 : 6,
            height: isLarge ? 8 : 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: isLarge ? 16 : 13, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: isLarge ? 13 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
